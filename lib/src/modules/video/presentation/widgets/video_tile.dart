import 'package:flutter/material.dart';

import '../../../../shared/utils/duration_format.dart';
import '../../domain/video.dart';
import 'playback_progress_bar.dart';
import 'video_thumbnail.dart';

class VideoTile extends StatelessWidget {
  const VideoTile({
    required this.video,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.onTap,
    this.onLongPress,
    this.onPreview,
    this.onDetails,
    this.selected = false,
    super.key,
  });

  final Video video;
  final bool showPlaybackProgress;
  final bool showTags;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPreview;
  final VoidCallback? onDetails;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final progress = video.playbackProgress;
    final showProgress = showPlaybackProgress && video.hasPlaybackProgress;
    final dateLabel = video.modifiedAt != null
        ? '更新 ${formatDate(video.modifiedAt)}'
        : video.createdAt != null
            ? '作成 ${formatDate(video.createdAt)}'
            : null;
    final sizeLabel = formatFileSize(video.sizeBytes);
    final semanticParts = [
      video.displayName,
      '再生時間 ${formatDuration(video.duration)}',
      'フォルダ ${video.folderName}',
      if (dateLabel != null) dateLabel,
      if (sizeLabel != '--') 'サイズ $sizeLabel',
      if (selected) '選択中',
      if (!video.isPlayable) '再生不可',
      if (showProgress) '視聴進捗 ${(progress * 100).round()}パーセント',
      if (showTags && video.tags.isNotEmpty) 'タグ ${video.tags.join('、')}',
    ];

    return Semantics(
      button: true,
      selected: selected,
      label: semanticParts.join('。'),
      onTapHint: selected ? '選択を解除します' : '動画を再生します',
      onLongPressHint: onLongPress == null ? null : '動画を選択します',
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnail(video: video),
                    Positioned(
                      right: 8,
                      bottom: showProgress ? 8 : 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            formatDuration(video.duration),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    if (showProgress)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: PlaybackProgressBar(progress: progress),
                      ),
                    if (selected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.20),
                          ),
                        ),
                      ),
                    if (selected)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            video.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (onPreview != null)
                          SizedBox.square(
                            dimension: 48,
                            child: IconButton(
                              tooltip: '簡易再生',
                              iconSize: 18,
                              onPressed: onPreview,
                              icon: const Icon(Icons.play_circle_outline),
                            ),
                          ),
                        if (onDetails != null)
                          SizedBox.square(
                            dimension: 48,
                            child: IconButton(
                              tooltip: '詳細',
                              iconSize: 18,
                              onPressed: onDetails,
                              icon: const Icon(Icons.more_vert),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.folderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (dateLabel != null || sizeLabel != '--') ...[
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (dateLabel != null) dateLabel,
                          if (sizeLabel != '--') sizeLabel,
                        ].join(' ・ '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (showTags && video.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final tag in video.tags)
                            Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
