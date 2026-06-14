import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../shared/utils/duration_format.dart';
import '../../../shared/utils/file_name_utils.dart';
import '../../playback/presentation/full_screen_player_screen.dart';
import '../../playlist/application/playlist_providers.dart';
import '../../playlist/domain/playlist.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/private_access_auth.dart';
import '../application/video_providers.dart';
import '../domain/video.dart';
import '../domain/video_query.dart';
import 'widgets/file_conflict_dialog.dart';
import 'widgets/relative_path_picker_dialog.dart';
import 'widgets/video_thumbnail.dart';

class VideoDetailScreen extends ConsumerWidget {
  const VideoDetailScreen({
    required this.videoId,
    super.key,
  });

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(videoByIdProvider(videoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('動画詳細'),
        actions: [
          PopupMenuButton<_VideoDetailAction>(
            onSelected: (action) {
              final video = videoAsync.valueOrNull;
              if (video == null) {
                return;
              }

              switch (action) {
                case _VideoDetailAction.rename:
                  unawaited(_showRenameDialog(context, ref, video));
                case _VideoDetailAction.move:
                  unawaited(_showRelativePathDialog(context, ref, video, true));
                case _VideoDetailAction.copy:
                  unawaited(
                      _showRelativePathDialog(context, ref, video, false));
                case _VideoDetailAction.delete:
                  unawaited(_confirmDelete(context, ref, video));
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _VideoDetailAction.rename,
                child: ListTile(
                  leading: Icon(Icons.drive_file_rename_outline),
                  title: Text('名前変更'),
                ),
              ),
              PopupMenuItem(
                value: _VideoDetailAction.move,
                child: ListTile(
                  leading: Icon(Icons.drive_file_move_outline),
                  title: Text('移動'),
                ),
              ),
              PopupMenuItem(
                value: _VideoDetailAction.copy,
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('コピー'),
                ),
              ),
              PopupMenuItem(
                value: _VideoDetailAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('削除'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: videoAsync.when(
        data: (video) {
          if (video == null) {
            return const Center(child: Text('動画が見つかりません'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoThumbnail(video: video),
                      Center(
                        child: IconButton.filled(
                          iconSize: 40,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    FullScreenPlayerScreen(videoId: video.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                video.displayName,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (video.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in video.tags)
                      Chip(
                        label: Text(tag),
                        avatar: const Icon(Icons.label_outline, size: 18),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              FullScreenPlayerScreen(videoId: video.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('再生'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => unawaited(_share(context, ref, video)),
                    icon: const Icon(Icons.ios_share),
                    label: const Text('共有'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        unawaited(_openEditor(context, ref, video)),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集アプリ'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        unawaited(_openExternalPlayer(context, ref, video)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('外部再生'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        unawaited(_showPlaylistDialog(context, ref, video)),
                    icon: const Icon(Icons.playlist_add),
                    label: const Text('リスト追加'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        unawaited(_toggleFavorite(context, ref, video)),
                    icon: Icon(
                      video.isFavorite ? Icons.star : Icons.star_border,
                    ),
                    label: Text(video.isFavorite ? 'お気に入り解除' : 'お気に入り'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        unawaited(_togglePrivate(context, ref, video)),
                    icon: Icon(
                      video.isPrivate
                          ? Icons.visibility
                          : Icons.visibility_off_outlined,
                    ),
                    label: Text(video.isPrivate ? '非表示解除' : '非表示'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        unawaited(_showRenameDialog(context, ref, video)),
                    icon: const Icon(Icons.drive_file_rename_outline),
                    label: const Text('名前変更'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(
                      _showRelativePathDialog(context, ref, video, true),
                    ),
                    icon: const Icon(Icons.drive_file_move_outline),
                    label: const Text('移動'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(
                      _showRelativePathDialog(context, ref, video, false),
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text('コピー'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _copyLocation(context, video),
                    icon: const Icon(Icons.content_copy),
                    label: const Text('場所コピー'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DetailSection(
                rows: [
                  _DetailRow(label: 'フォルダ', value: video.folderName),
                  _DetailRow(label: '保存場所', value: video.relativePath ?? '--'),
                  _DetailRow(label: 'MIMEタイプ', value: video.mimeType ?? '--'),
                  _DetailRow(
                      label: '再生時間', value: formatDuration(video.duration)),
                  _DetailRow(
                      label: 'サイズ', value: formatFileSize(video.sizeBytes)),
                  _DetailRow(
                    label: '解像度',
                    value: formatResolution(
                      width: video.width,
                      height: video.height,
                      rotationDegrees: video.rotationDegrees,
                    ),
                  ),
                  _DetailRow(
                      label: 'ビットレート', value: formatBitrate(video.bitrate)),
                  _DetailRow(
                    label: 'フレームレート',
                    value: formatFrameRate(video.frameRate),
                  ),
                  _DetailRow(
                    label: '再生可否',
                    value: video.isPlayable
                        ? '再生可能'
                        : '再生不可: ${video.playbackUnavailableReason ?? '理由を取得できませんでした'}',
                  ),
                  _DetailRow(
                    label: '字幕',
                    value: video.subtitleUri?.toString() ?? '--',
                  ),
                  _DetailRow(label: '作成日', value: formatDate(video.createdAt)),
                  _DetailRow(label: '更新日', value: formatDate(video.modifiedAt)),
                  _DetailRow(
                    label: '前回位置',
                    value: formatDuration(video.lastPlayedPosition),
                  ),
                  _DetailRow(label: 'URI', value: video.uri.toString()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => unawaited(_confirmDelete(context, ref, video)),
                icon: const Icon(Icons.delete_outline),
                label: const Text('削除'),
              ),
            ],
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    try {
      await ref.read(videoRepositoryProvider).shareVideo(video.id);
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '共有できませんでした: $error');
      }
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    try {
      await ref.read(videoRepositoryProvider).openVideoInEditor(video.id);
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '編集アプリを開けませんでした: $error');
      }
    }
  }

  Future<void> _openExternalPlayer(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    try {
      await ref
          .read(videoRepositoryProvider)
          .openVideoInExternalPlayer(video.id);
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '外部プレイヤーを開けませんでした: $error');
      }
    }
  }

  void _copyLocation(BuildContext context, Video video) {
    final location = video.relativePath?.isNotEmpty == true
        ? '${video.relativePath}${video.displayName}'
        : video.uri.toString();
    Clipboard.setData(ClipboardData(text: location));
    _showSnackBar(context, '保存場所をコピーしました');
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    try {
      await ref.read(videoRepositoryProvider).setFavorite(
            videoId: video.id,
            isFavorite: !video.isFavorite,
          );
      ref.invalidate(videoByIdProvider(video.id));
      if (context.mounted) {
        _showSnackBar(
          context,
          video.isFavorite ? 'お気に入りを解除しました' : 'お気に入りに追加しました',
        );
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, 'お気に入りを更新できませんでした: $error');
      }
    }
  }

  Future<void> _togglePrivate(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final settings = await ref.read(appSettingsProvider.future);
    if (!context.mounted) {
      return;
    }

    final authenticated = await _authenticatePrivateAccess(
      context,
      ref,
      settings,
    );
    if (!authenticated) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(video.isPrivate ? '非表示を解除' : '動画を非表示'),
        content: Text.rich(
          TextSpan(
            children: video.isPrivate
                ? [
                    TextSpan(text: '${video.displayName} を通常の一覧へ戻します。\n\n'),
                    const TextSpan(
                      text: '解除後は元の保存先へ戻し、通常の一覧・検索結果に再表示します。',
                    ),
                  ]
                : [
                    TextSpan(
                      text: '${video.displayName} を専用フォルダへ移動し、通常の一覧から隠します。\n\n',
                    ),
                    const TextSpan(text: '注意事項\n'),
                    const TextSpan(text: '・移動にはAndroidの確認が表示される場合があります。\n'),
                    const TextSpan(text: '・アプリ削除時に元の保存先を復元できない場合があります。\n'),
                    const TextSpan(text: '・フィルタの「非表示」からPIN確認後に表示できます。'),
                  ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(video.isPrivate ? '解除' : '非表示'),
          ),
        ],
      ),
    );

    if (shouldUpdate != true) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).setPrivate(
            videoId: video.id,
            isPrivate: !video.isPrivate,
          );
      ref.invalidate(videoByIdProvider(video.id));
      if (context.mounted) {
        _showSnackBar(context, video.isPrivate ? '非表示を解除しました' : '非表示にしました');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '非表示を更新できませんでした: $error');
      }
    }
  }

  Future<bool> _authenticatePrivateAccess(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    return authenticatePrivateAccess(
      context,
      ref,
      settings,
      confirmLabel: '確認',
    );
  }

  Future<void> _showPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final playlists = await ref.read(playlistsProvider.future);
    if (!context.mounted) {
      return;
    }

    final selected = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('新しいプレイリスト'),
              onTap: () =>
                  Navigator.of(context).pop(const _CreatePlaylistSelection()),
            ),
            for (final playlist in playlists)
              ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.videoCount}件の動画'),
                onTap: () => Navigator.of(context).pop(playlist),
              ),
          ],
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    final Playlist playlist;
    if (selected == null) {
      return;
    } else if (selected is _CreatePlaylistSelection) {
      final created = await _showCreatePlaylistDialog(context, ref);
      if (created == null) {
        return;
      }
      playlist = created;
    } else {
      playlist = selected as Playlist;
    }

    await ref.read(playlistRepositoryProvider).addVideo(
          playlistId: playlist.id,
          videoId: video.id,
        );

    if (context.mounted) {
      _showSnackBar(context, '${playlist.name} に追加しました');
    }
  }

  Future<Playlist?> _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレイリスト作成'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名前'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('作成'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null) {
      return null;
    }

    return ref.read(playlistRepositoryProvider).createPlaylist(name);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除'),
        content: Text('${video.displayName} を端末から削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).deleteVideo(video.id);
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(const SnackBar(content: Text('削除しました')));
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '削除できませんでした: $error');
      }
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Video video,
  ) async {
    final extension = fileNameExtension(video.displayName);
    final controller = TextEditingController(
      text: fileNameBase(video.displayName),
    );
    final nextBaseName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'ファイル名'),
            ),
            if (extension.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '拡張子 $extension は維持されます',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (nextBaseName == null || nextBaseName.isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    if (attemptsExtensionChange(
      baseName: nextBaseName,
      originalExtension: extension,
    )) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('拡張子は変更されません'),
          content: Text(
            '入力された拡張子ではなく、元の拡張子 $extension を維持して保存します。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('戻る'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('続行'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return;
      }
    }

    final nextName = composeDisplayName(
      baseName: nextBaseName,
      extension: extension,
    );
    if (nextName == video.displayName) {
      return;
    }

    final validationMessage = validateFileName(nextName);
    if (validationMessage != null) {
      if (context.mounted) {
        _showSnackBar(context, validationMessage);
      }
      return;
    }

    final videos = await _loadKnownVideos(ref);
    if (_hasDuplicateVideo(
      videos,
      relativePath: video.relativePath,
      displayName: nextName,
      exceptVideoId: video.id,
    )) {
      if (context.mounted) {
        _showSnackBar(context, '同じフォルダに同名の動画があります');
      }
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).renameVideo(
            videoId: video.id,
            displayName: nextName,
          );
      if (context.mounted) {
        _showSnackBar(context, '名前を変更しました');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(context, '名前変更できませんでした: $error');
      }
    }
  }

  Future<void> _showRelativePathDialog(
    BuildContext context,
    WidgetRef ref,
    Video video,
    bool isMove,
  ) async {
    final videos = await _loadKnownVideos(ref);
    if (!context.mounted) {
      return;
    }

    final relativePath = await showDialog<String>(
      context: context,
      builder: (context) => RelativePathPickerDialog(
        title: isMove ? '移動先フォルダ' : 'コピー先フォルダ',
        actionLabel: isMove ? '移動' : 'コピー',
        initialPath: video.relativePath ?? 'Movies',
        inputLabel: isMove ? '移動先フォルダ' : 'コピー先フォルダ',
        folderOptions:
            videos.map((video) => video.relativePath).whereType<String>(),
      ),
    );

    if (relativePath == null || relativePath.isEmpty) {
      return;
    }

    final validationMessage = validateRelativePath(relativePath);
    if (validationMessage != null) {
      if (context.mounted) {
        _showSnackBar(context, validationMessage);
      }
      return;
    }

    final normalizedPath = normalizeRelativePath(relativePath)!;
    var copyDisplayName = video.displayName;
    final destinationNames = _destinationDisplayNames(
      videos,
      relativePath: normalizedPath,
      exceptVideoId: isMove ? video.id : null,
    );
    final conflictVideo = _findDuplicateVideo(
      videos,
      relativePath: normalizedPath,
      displayName: video.displayName,
      exceptVideoId: isMove ? video.id : null,
    );
    if (conflictVideo != null) {
      if (!context.mounted) {
        return;
      }
      final resolution = await showFileConflictDialog(
        context: context,
        isMove: isMove,
        isBatch: false,
        conflictCount: 1,
      );

      if (resolution == null ||
          resolution == FileConflictResolution.skip ||
          (isMove && resolution == FileConflictResolution.rename)) {
        return;
      }

      if (resolution == FileConflictResolution.rename) {
        copyDisplayName = nextAvailableDisplayName(
          desiredDisplayName: video.displayName,
          existingDisplayNames: destinationNames,
        );
      } else if (resolution == FileConflictResolution.replace) {
        try {
          await ref.read(videoRepositoryProvider).deleteVideo(conflictVideo.id);
        } catch (error) {
          if (context.mounted) {
            _showSnackBar(context, '置き換え対象を削除できませんでした: $error');
          }
          return;
        }
      }
    }

    try {
      if (isMove) {
        await ref.read(videoRepositoryProvider).moveVideo(
              videoId: video.id,
              relativePath: normalizedPath,
            );
      } else {
        await ref.read(videoRepositoryProvider).copyVideo(
              videoId: video.id,
              relativePath: normalizedPath,
              displayName: copyDisplayName,
            );
      }

      if (context.mounted) {
        _showSnackBar(context, isMove ? '移動しました' : 'コピーしました');
      }
    } catch (error) {
      if (context.mounted) {
        _showSnackBar(
          context,
          '${isMove ? '移動' : 'コピー'}できませんでした: $error',
        );
      }
    }
  }

  Future<List<Video>> _loadKnownVideos(WidgetRef ref) async {
    final repository = ref.read(videoRepositoryProvider);
    final publicVideos = await repository.watchVideos(const VideoQuery()).first;
    final privateVideos = await repository
        .watchVideos(const VideoQuery(filter: VideoFilter.privateVideos))
        .first;

    return {
      for (final video in [...publicVideos, ...privateVideos]) video.id: video,
    }.values.toList(growable: false);
  }

  bool _hasDuplicateVideo(
    List<Video> videos, {
    required String? relativePath,
    required String displayName,
    String? exceptVideoId,
  }) {
    final normalizedPath =
        relativePath == null ? null : normalizeRelativePath(relativePath);
    return videos.any((video) {
      if (video.id == exceptVideoId) {
        return false;
      }

      return normalizeRelativePath(video.relativePath ?? '') ==
              normalizedPath &&
          video.displayName.toLowerCase() == displayName.toLowerCase();
    });
  }

  Video? _findDuplicateVideo(
    List<Video> videos, {
    required String? relativePath,
    required String displayName,
    String? exceptVideoId,
  }) {
    final normalizedPath =
        relativePath == null ? null : normalizeRelativePath(relativePath);
    for (final video in videos) {
      if (video.id == exceptVideoId) {
        continue;
      }

      if (normalizeRelativePath(video.relativePath ?? '') == normalizedPath &&
          video.displayName.toLowerCase() == displayName.toLowerCase()) {
        return video;
      }
    }

    return null;
  }

  List<String> _destinationDisplayNames(
    List<Video> videos, {
    required String relativePath,
    String? exceptVideoId,
  }) {
    final normalizedPath = normalizeRelativePath(relativePath);
    return [
      for (final video in videos)
        if (video.id != exceptVideoId &&
            normalizeRelativePath(video.relativePath ?? '') == normalizedPath)
          video.displayName,
    ];
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              title: Text(row.label),
              subtitle: Text(
                row.value,
                maxLines: row.isLongValue ? 4 : null,
                overflow:
                    row.isLongValue ? TextOverflow.ellipsis : TextOverflow.clip,
                softWrap: true,
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  bool get isLongValue => value.length > 48 || value.contains('://');
}

enum _VideoDetailAction {
  rename,
  move,
  copy,
  delete,
}

class _CreatePlaylistSelection {
  const _CreatePlaylistSelection();
}
