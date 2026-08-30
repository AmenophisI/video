import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/duration_format.dart';
import '../../settings/application/settings_providers.dart';
import '../../video/domain/video.dart';
import '../application/playback_providers.dart';
import 'full_screen_player_screen.dart';
import 'widgets/native_video_player_view.dart';

class QuickPreviewSheet extends ConsumerStatefulWidget {
  const QuickPreviewSheet({
    required this.video,
    super.key,
  });

  final Video video;

  @override
  ConsumerState<QuickPreviewSheet> createState() => _QuickPreviewSheetState();
}

class _QuickPreviewSheetState extends ConsumerState<QuickPreviewSheet> {
  final NativeVideoPlayerController _controller = NativeVideoPlayerController();

  bool _isPlaying = true;
  bool _isMuted = false;
  bool _isSubtitleEnabled = true;

  @override
  void dispose() {
    unawaited(_saveCurrentPosition());
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final shouldResume = settings?.rememberPlaybackPosition ?? true;
    final initialPosition = shouldResume
        ? widget.video.lastPlayedPosition ?? Duration.zero
        : Duration.zero;

    if (!widget.video.isPlayable) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 20),
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(
                'この動画はアプリ内で再生できません',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.video.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.video.playbackUnavailableReason != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.video.playbackUnavailableReason!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FullScreenPlayerScreen(
                        videoId: widget.video.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_full),
                label: const Text('詳細を開く'),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: NativeVideoPlayerView(
                  controller: _controller,
                  uri: widget.video.uri,
                  initialPosition: initialPosition,
                  subtitleUri: widget.video.subtitleUri,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.video.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDuration(initialPosition)} / ${formatDuration(widget.video.duration)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                IconButton.filledTonal(
                  tooltip: '10秒戻る',
                  onPressed: () =>
                      unawaited(_seekBy(const Duration(seconds: -10))),
                  icon: const Icon(Icons.replay_10),
                ),
                IconButton.filled(
                  tooltip: _isPlaying ? '一時停止' : '再生',
                  onPressed: () => unawaited(_togglePlayback()),
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
                IconButton.filledTonal(
                  tooltip: '10秒進む',
                  onPressed: () =>
                      unawaited(_seekBy(const Duration(seconds: 10))),
                  icon: const Icon(Icons.forward_10),
                ),
                IconButton.filledTonal(
                  tooltip: _isMuted ? '音声ON' : '音声OFF',
                  onPressed: () => unawaited(_toggleMuted()),
                  icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
                ),
                if (widget.video.subtitleUri != null)
                  IconButton.filledTonal(
                    tooltip: _isSubtitleEnabled ? '字幕OFF' : '字幕ON',
                    onPressed: () => unawaited(_toggleSubtitle()),
                    icon: Icon(
                      _isSubtitleEnabled
                          ? Icons.closed_caption
                          : Icons.closed_caption_disabled,
                    ),
                  ),
                IconButton.filledTonal(
                  tooltip: '全画面',
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FullScreenPlayerScreen(
                          videoId: widget.video.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _controller.pause();
    } else {
      await _controller.play();
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _seekBy(Duration offset) async {
    final currentPosition = await _controller.currentPosition();
    if (currentPosition == null) {
      return;
    }

    final duration = await _controller.duration() ?? widget.video.duration;
    var nextPosition = currentPosition + offset;
    if (nextPosition < Duration.zero) {
      nextPosition = Duration.zero;
    }
    if (duration != null && nextPosition > duration) {
      nextPosition = duration;
    }

    await _controller.seekTo(nextPosition);
  }

  Future<void> _toggleMuted() async {
    final nextMuted = !_isMuted;
    await _controller.setMuted(nextMuted);
    if (mounted) {
      setState(() {
        _isMuted = nextMuted;
      });
    }
  }

  Future<void> _toggleSubtitle() async {
    final nextEnabled = !_isSubtitleEnabled;
    await _controller.setSubtitleEnabled(nextEnabled);
    if (mounted) {
      setState(() {
        _isSubtitleEnabled = nextEnabled;
      });
    }
  }

  Future<void> _saveCurrentPosition() async {
    final position = await _controller.currentPosition();
    if (position == null || position <= Duration.zero) {
      return;
    }

    await ref.read(savePlaybackPositionUseCaseProvider).call(
          videoId: widget.video.id,
          position: position,
        );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 34,
        height: 5,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
