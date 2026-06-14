import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../shared/utils/duration_format.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../application/playback_providers.dart';
import 'widgets/native_video_player_view.dart';

class FullScreenPlayerScreen extends ConsumerStatefulWidget {
  const FullScreenPlayerScreen({
    required this.videoId,
    this.playlistVideoIds = const [],
    this.playlistInitialIndex = 0,
    super.key,
  });

  final String videoId;
  final List<String> playlistVideoIds;
  final int playlistInitialIndex;

  @override
  ConsumerState<FullScreenPlayerScreen> createState() =>
      _FullScreenPlayerScreenState();
}

class _FullScreenPlayerScreenState
    extends ConsumerState<FullScreenPlayerScreen> {
  final NativeVideoPlayerController _playerController =
      NativeVideoPlayerController();

  late String _currentVideoId;
  late int _currentPlaylistIndex;
  StreamSubscription<void>? _completedSubscription;
  Timer? _positionTimer;

  bool _canPop = false;
  bool _isSavingBeforePop = false;
  bool _isMuted = false;
  bool _isSubtitleEnabled = true;
  bool _isLandscape = false;
  bool _isPlaying = true;
  bool _isSeeking = false;
  bool _showControls = false;
  Duration _currentPosition = Duration.zero;
  Duration _currentDuration = Duration.zero;
  Duration? _dragSeekStartPosition;
  Duration _dragSeekOffset = Duration.zero;

  List<String> get _playlistVideoIds {
    if (widget.playlistVideoIds.isEmpty) {
      return [widget.videoId];
    }

    return widget.playlistVideoIds;
  }

  bool get _hasNext => _currentPlaylistIndex < _playlistVideoIds.length - 1;

  bool get _hasPrevious => _currentPlaylistIndex > 0;

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.videoId;
    _currentPlaylistIndex = widget.playlistVideoIds.isEmpty
        ? 0
        : widget.playlistInitialIndex
            .clamp(0, widget.playlistVideoIds.length - 1);
    _completedSubscription = _playerController.completed.listen((_) {
      unawaited(_handlePlaybackCompleted());
    });
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => unawaited(_syncPlaybackState()),
    );
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _completedSubscription?.cancel();
    unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(playbackVideoProvider(_currentVideoId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: videoAsync.when(
        data: (video) {
          if (video == null) {
            return const Center(
              child: Text(
                '動画が見つかりません',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!video.isPlayable) {
            return _UnplayableVideoPanel(
              videoName: video.displayName,
              reason: video.playbackUnavailableReason,
              hasNext: _hasNext,
              hasPrevious: _hasPrevious,
              onOpenExternalPlayer: () =>
                  unawaited(_openExternalPlayer(video.id)),
              onPrevious: _hasPrevious
                  ? () => unawaited(_playPrevious(video.id))
                  : null,
              onNext: _hasNext ? () => unawaited(_playNext(video.id)) : null,
            );
          }

          final resumePosition = video.lastPlayedPosition ?? Duration.zero;
          final displayDuration = _currentDuration > Duration.zero
              ? _currentDuration
              : video.duration ?? Duration.zero;
          final displayPosition = _currentPosition > Duration.zero
              ? _currentPosition
              : resumePosition;
          final durationMs = displayDuration.inMilliseconds;
          final positionMs = displayPosition.inMilliseconds.clamp(
            0,
            durationMs <= 0 ? 0 : durationMs,
          );

          return PopScope<void>(
            canPop: _canPop,
            onPopInvokedWithResult: (didPop, _) {
              if (didPop || _isSavingBeforePop) {
                return;
              }

              unawaited(_saveAndPop(video.id));
            },
            child: SafeArea(
              child: _buildPlayerOverlay(
                context: context,
                video: video,
                resumePosition: resumePosition,
                displayDuration: displayDuration,
                positionMs: positionMs,
                durationMs: durationMs,
              ),
            ),
          );
        },
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildVideoSurface({
    required Video video,
    required Duration resumePosition,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.black,
        child: NativeVideoPlayerView(
          key: ValueKey(video.id),
          controller: _playerController,
          uri: video.uri,
          initialPosition: resumePosition,
          subtitleUri: video.subtitleUri,
        ),
      ),
    );
  }

  Widget _buildPlayerOverlay({
    required BuildContext context,
    required Video video,
    required Duration resumePosition,
    required Duration displayDuration,
    required int positionMs,
    required int durationMs,
  }) {
    final aspectRatio = _videoAspectRatio(video);
    final dragTargetPosition = _dragTargetPosition(displayDuration);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeLayout = constraints.maxWidth > constraints.maxHeight;
        final horizontalPadding = isLandscapeLayout ? 0.0 : 0.0;
        final verticalPadding = isLandscapeLayout ? 0.0 : 0.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: _buildVideoSurface(
                    video: video,
                    resumePosition: resumePosition,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControlsVisibility,
                onHorizontalDragStart: (_) => _startDragSeek(),
                onHorizontalDragUpdate: (details) =>
                    _updateDragSeek(details.primaryDelta ?? 0),
                onHorizontalDragEnd: (_) =>
                    unawaited(_finishDragSeek(displayDuration)),
                child: const SizedBox.expand(),
              ),
            ),
            if (_showControls)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: false,
                  child: _PlayerControlsOverlay(
                    video: video,
                    isLandscapeLayout: isLandscapeLayout,
                    isPlaying: _isPlaying,
                    isMuted: _isMuted,
                    isSubtitleEnabled: _isSubtitleEnabled,
                    isLandscape: _isLandscape,
                    isSavingBeforePop: _isSavingBeforePop,
                    hasPrevious: _hasPrevious,
                    hasNext: _hasNext,
                    playlistPosition:
                        '${_currentPlaylistIndex + 1}/${_playlistVideoIds.length}',
                    positionText: formatDuration(
                      Duration(milliseconds: positionMs),
                    ),
                    durationText: formatDuration(displayDuration),
                    sliderValue: durationMs <= 0 ? 0 : positionMs.toDouble(),
                    sliderMax: durationMs <= 0 ? 1 : durationMs.toDouble(),
                    onClose: () => Navigator.of(context).maybePop(),
                    onDismiss: _toggleControlsVisibility,
                    onTogglePlayback: _isSavingBeforePop
                        ? null
                        : () => unawaited(_togglePlayback()),
                    onSeekBack: _isSavingBeforePop
                        ? null
                        : () =>
                            unawaited(_seekBy(const Duration(seconds: -10))),
                    onSeekForward: _isSavingBeforePop
                        ? null
                        : () => unawaited(_seekBy(const Duration(seconds: 10))),
                    onPrevious: _hasPrevious && !_isSavingBeforePop
                        ? () => unawaited(_playPrevious(video.id))
                        : null,
                    onNext: _hasNext && !_isSavingBeforePop
                        ? () => unawaited(_playNext(video.id))
                        : null,
                    onToggleMuted: _isSavingBeforePop
                        ? null
                        : () => unawaited(_toggleMuted()),
                    onToggleOrientation: _isSavingBeforePop
                        ? null
                        : () => unawaited(_toggleOrientation()),
                    onToggleSubtitle:
                        video.subtitleUri != null && !_isSavingBeforePop
                            ? () => unawaited(_toggleSubtitle())
                            : null,
                    onOpenExternalPlayer: _isSavingBeforePop
                        ? null
                        : () => unawaited(_openExternalPlayer(video.id)),
                    onSaveAndPop: _isSavingBeforePop
                        ? null
                        : () => unawaited(_saveAndPop(video.id)),
                    onSliderChangeStart: durationMs <= 0
                        ? null
                        : (_) {
                            setState(() {
                              _isSeeking = true;
                            });
                          },
                    onSliderChanged: durationMs <= 0
                        ? null
                        : (value) {
                            setState(() {
                              _currentPosition = Duration(
                                milliseconds: value.round(),
                              );
                            });
                          },
                    onSliderChangeEnd: durationMs <= 0
                        ? null
                        : (value) {
                            unawaited(
                              _seekTo(Duration(milliseconds: value.round())),
                            );
                          },
                  ),
                ),
              ),
            if (_dragSeekOffset != Duration.zero && dragTargetPosition != null)
              Center(
                child: _SeekPreview(
                  targetPosition: dragTargetPosition,
                  offset: _dragSeekOffset,
                ),
              ),
          ],
        );
      },
    );
  }

  double _videoAspectRatio(Video video) {
    final width = video.width;
    final height = video.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 16 / 9;
    }

    final rotated = video.rotationDegrees == 90 || video.rotationDegrees == 270;
    return rotated ? height / width : width / height;
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _startDragSeek() async {
    final position = await _playerController.currentPosition();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSeeking = true;
      _dragSeekStartPosition = position ?? _currentPosition;
      _dragSeekOffset = Duration.zero;
      _showControls = false;
    });
  }

  void _updateDragSeek(double delta) {
    final currentOffsetMs = _dragSeekOffset.inMilliseconds;
    final nextOffsetMs = currentOffsetMs + (delta * 80).round();
    setState(() {
      _dragSeekOffset = Duration(milliseconds: nextOffsetMs);
    });
  }

  Duration? _dragTargetPosition(Duration duration) {
    final start = _dragSeekStartPosition;
    if (start == null) {
      return null;
    }

    return _clampPosition(start + _dragSeekOffset, duration);
  }

  Future<void> _finishDragSeek(Duration duration) async {
    final target = _dragTargetPosition(duration);
    if (target != null) {
      await _playerController.seekTo(target);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (target != null) {
        _currentPosition = target;
      }
      _dragSeekStartPosition = null;
      _dragSeekOffset = Duration.zero;
      _isSeeking = false;
    });
  }

  Duration _clampPosition(Duration position, Duration duration) {
    if (position < Duration.zero) {
      return Duration.zero;
    }
    if (duration > Duration.zero && position > duration) {
      return duration;
    }
    return position;
  }

  Future<void> _handlePlaybackCompleted() async {
    await _saveCurrentPosition(_currentVideoId);
    if (!_hasNext) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentPlaylistIndex += 1;
      _currentVideoId = _playlistVideoIds[_currentPlaylistIndex];
      _resetPlaybackUiState();
    });
  }

  Future<void> _playPrevious(String videoId) async {
    await _saveCurrentPosition(videoId);
    if (!mounted || !_hasPrevious) {
      return;
    }

    setState(() {
      _currentPlaylistIndex -= 1;
      _currentVideoId = _playlistVideoIds[_currentPlaylistIndex];
      _resetPlaybackUiState();
    });
  }

  Future<void> _playNext(String videoId) async {
    await _saveCurrentPosition(videoId);
    if (!mounted || !_hasNext) {
      return;
    }

    setState(() {
      _currentPlaylistIndex += 1;
      _currentVideoId = _playlistVideoIds[_currentPlaylistIndex];
      _resetPlaybackUiState();
    });
  }

  void _resetPlaybackUiState() {
    _isPlaying = true;
    _isSubtitleEnabled = true;
    _isSeeking = false;
    _currentPosition = Duration.zero;
    _currentDuration = Duration.zero;
  }

  Future<void> _syncPlaybackState() async {
    if (!mounted || _isSeeking) {
      return;
    }

    final position = await _playerController.currentPosition();
    final duration = await _playerController.duration();
    final isPlaying = await _playerController.isPlaying();
    if (!mounted) {
      return;
    }

    setState(() {
      if (position != null) {
        _currentPosition = position;
      }
      if (duration != null && duration > Duration.zero) {
        _currentDuration = duration;
      }
      if (isPlaying != null) {
        _isPlaying = isPlaying;
      }
    });
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _playerController.pause();
    } else {
      await _playerController.play();
    }

    if (mounted) {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  Future<void> _seekBy(Duration offset) async {
    final currentPosition = await _playerController.currentPosition();
    if (currentPosition == null) {
      return;
    }

    final duration = await _playerController.duration();
    var nextPosition = currentPosition + offset;
    if (nextPosition < Duration.zero) {
      nextPosition = Duration.zero;
    }
    if (duration != null &&
        duration > Duration.zero &&
        nextPosition > duration) {
      nextPosition = duration;
    }

    await _playerController.seekTo(nextPosition);
    if (mounted) {
      setState(() {
        _currentPosition = nextPosition;
      });
    }
  }

  Future<void> _seekTo(Duration position) async {
    try {
      await _playerController.seekTo(position);
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
      }
    }
  }

  Future<void> _openExternalPlayer(String videoId) async {
    try {
      await _saveCurrentPosition(videoId);
      await ref
          .read(videoRepositoryProvider)
          .openVideoInExternalPlayer(videoId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('外部プレイヤーを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _toggleMuted() async {
    final nextMuted = !_isMuted;
    await _playerController.setMuted(nextMuted);
    if (mounted) {
      setState(() {
        _isMuted = nextMuted;
      });
    }
  }

  Future<void> _toggleSubtitle() async {
    final nextEnabled = !_isSubtitleEnabled;
    await _playerController.setSubtitleEnabled(nextEnabled);
    if (mounted) {
      setState(() {
        _isSubtitleEnabled = nextEnabled;
      });
    }
  }

  Future<void> _toggleOrientation() async {
    final nextLandscape = !_isLandscape;
    if (nextLandscape) {
      await SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
      );
    } else {
      await SystemChrome.setPreferredOrientations(
        const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      );
    }

    if (mounted) {
      setState(() {
        _isLandscape = nextLandscape;
      });
    }
  }

  Future<void> _saveAndPop(String videoId) async {
    if (_isSavingBeforePop) {
      return;
    }

    setState(() {
      _isSavingBeforePop = true;
    });

    await _saveCurrentPosition(videoId);

    if (!mounted) {
      return;
    }

    setState(() {
      _canPop = true;
      _isSavingBeforePop = false;
    });
    Navigator.of(context).pop();
  }

  Future<void> _saveCurrentPosition(String videoId) async {
    final position = await _playerController.currentPosition();
    if (position == null || position <= Duration.zero) {
      return;
    }

    await ref.read(savePlaybackPositionUseCaseProvider).call(
          videoId: videoId,
          position: position,
        );
  }
}

class _PlayerControlsOverlay extends StatelessWidget {
  const _PlayerControlsOverlay({
    required this.video,
    required this.isLandscapeLayout,
    required this.isPlaying,
    required this.isMuted,
    required this.isSubtitleEnabled,
    required this.isLandscape,
    required this.isSavingBeforePop,
    required this.hasPrevious,
    required this.hasNext,
    required this.playlistPosition,
    required this.positionText,
    required this.durationText,
    required this.sliderValue,
    required this.sliderMax,
    required this.onClose,
    required this.onDismiss,
    required this.onTogglePlayback,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleMuted,
    required this.onToggleOrientation,
    required this.onToggleSubtitle,
    required this.onOpenExternalPlayer,
    required this.onSaveAndPop,
    required this.onSliderChangeStart,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
  });

  final Video video;
  final bool isLandscapeLayout;
  final bool isPlaying;
  final bool isMuted;
  final bool isSubtitleEnabled;
  final bool isLandscape;
  final bool isSavingBeforePop;
  final bool hasPrevious;
  final bool hasNext;
  final String playlistPosition;
  final String positionText;
  final String durationText;
  final double sliderValue;
  final double sliderMax;
  final VoidCallback onClose;
  final VoidCallback onDismiss;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onSeekBack;
  final VoidCallback? onSeekForward;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onToggleMuted;
  final VoidCallback? onToggleOrientation;
  final VoidCallback? onToggleSubtitle;
  final VoidCallback? onOpenExternalPlayer;
  final VoidCallback? onSaveAndPop;
  final ValueChanged<double>? onSliderChangeStart;
  final ValueChanged<double>? onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = isLandscapeLayout ? 10.0 : 20.0;
    final sidePadding = isLandscapeLayout ? 24.0 : 18.0;
    final bottomPadding = isLandscapeLayout ? 18.0 : 28.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x99000000),
              Color(0x22000000),
              Color(0xAA000000),
            ],
            stops: [0, 0.48, 1],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            topPadding,
            sidePadding,
            bottomPadding,
          ),
          child: Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {},
                child: Row(
                  children: [
                    IconButton(
                      tooltip: '戻る',
                      onPressed: onClose,
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        video.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: isMuted ? 'ミュート解除' : 'ミュート',
                      onPressed: onToggleMuted,
                      color: Colors.white,
                      icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up),
                    ),
                    IconButton(
                      tooltip: isSubtitleEnabled ? '字幕OFF' : '字幕ON',
                      onPressed: onToggleSubtitle,
                      color: Colors.white,
                      icon: Icon(
                        isSubtitleEnabled
                            ? Icons.closed_caption
                            : Icons.closed_caption_disabled,
                      ),
                    ),
                    PopupMenuButton<_PlayerMenuAction>(
                      tooltip: 'その他',
                      iconColor: Colors.white,
                      onSelected: (action) {
                        switch (action) {
                          case _PlayerMenuAction.externalPlayer:
                            onOpenExternalPlayer?.call();
                          case _PlayerMenuAction.saveAndClose:
                            onSaveAndPop?.call();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _PlayerMenuAction.externalPlayer,
                          child: Text('外部プレイヤーで開く'),
                        ),
                        PopupMenuItem(
                          value: _PlayerMenuAction.saveAndClose,
                          child: Text('現在位置を保存して戻る'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniToolButton(
                      tooltip: isLandscape ? '縦向き' : '横向き',
                      onPressed: onToggleOrientation,
                      icon: Icons.screen_rotation,
                    ),
                    if (video.subtitleUri != null)
                      _MiniToolButton(
                        tooltip: isSubtitleEnabled ? '字幕OFF' : '字幕ON',
                        onPressed: onToggleSubtitle,
                        icon: isSubtitleEnabled
                            ? Icons.closed_caption
                            : Icons.closed_caption_disabled,
                      ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: '前へ',
                    onPressed: hasPrevious ? onPrevious : null,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filledTonal(
                    tooltip: '10秒戻る',
                    onPressed: onSeekBack,
                    icon: const Icon(Icons.replay_10),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filled(
                    tooltip: isPlaying ? '一時停止' : '再生',
                    iconSize: 36,
                    onPressed: onTogglePlayback,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filledTonal(
                    tooltip: '10秒進む',
                    onPressed: onSeekForward,
                    icon: const Icon(Icons.forward_10),
                  ),
                  const SizedBox(width: 18),
                  IconButton.filledTonal(
                    tooltip: '次へ',
                    onPressed: hasNext ? onNext : null,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    positionText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: sliderValue.clamp(0, sliderMax),
                      max: sliderMax,
                      onChangeStart: onSliderChangeStart,
                      onChanged: onSliderChanged,
                      onChangeEnd: onSliderChangeEnd,
                    ),
                  ),
                  Text(
                    durationText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomToolButton(
                    tooltip: '表示切替',
                    onPressed: onToggleOrientation,
                    icon: Icons.fit_screen,
                  ),
                  _BottomToolButton(
                    tooltip: 'プレイリスト位置',
                    onPressed: null,
                    text: playlistPosition,
                  ),
                  _BottomToolButton(
                    tooltip: '再生速度',
                    onPressed: null,
                    text: '1.0x',
                  ),
                  _BottomToolButton(
                    tooltip: isMuted ? 'ミュート解除' : 'ミュート',
                    onPressed: onToggleMuted,
                    icon: isMuted ? Icons.volume_off : Icons.volume_up,
                  ),
                  _BottomToolButton(
                    tooltip: isSavingBeforePop ? '保存中' : '保存して戻る',
                    onPressed: onSaveAndPop,
                    icon: Icons.lock_outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniToolButton extends StatelessWidget {
  const _MiniToolButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: Colors.white,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x33000000),
      ),
      icon: Icon(icon),
    );
  }
}

class _BottomToolButton extends StatelessWidget {
  const _BottomToolButton({
    required this.tooltip,
    this.icon,
    this.text,
    this.onPressed,
  });

  final String tooltip;
  final IconData? icon;
  final String? text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = text == null
        ? Icon(icon, size: 20)
        : Text(
            text!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          );

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 22,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0x33000000),
            shape: BoxShape.circle,
          ),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SeekPreview extends StatelessWidget {
  const _SeekPreview({
    required this.targetPosition,
    required this.offset,
  });

  final Duration targetPosition;
  final Duration offset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatDuration(targetPosition),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              '(${_formatSignedOffset(offset)})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSignedOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final absolute = offset.abs();
    final seconds = absolute.inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$sign${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

enum _PlayerMenuAction {
  externalPlayer,
  saveAndClose,
}

class _UnplayableVideoPanel extends StatelessWidget {
  const _UnplayableVideoPanel({
    required this.videoName,
    required this.reason,
    required this.hasNext,
    required this.hasPrevious,
    required this.onOpenExternalPlayer,
    this.onPrevious,
    this.onNext,
  });

  final String videoName;
  final String? reason;
  final bool hasNext;
  final bool hasPrevious;
  final VoidCallback onOpenExternalPlayer;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white70,
                              size: 56,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'この動画はアプリ内で再生できません',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              videoName,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            if (reason != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                reason!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white60,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 180,
                          child: OutlinedButton.icon(
                            onPressed: hasPrevious ? onPrevious : null,
                            icon: const Icon(Icons.skip_previous),
                            label: const Text('前へ'),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: OutlinedButton.icon(
                            onPressed: hasNext ? onNext : null,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('次へ'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onOpenExternalPlayer,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('外部プレイヤーで開く'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
