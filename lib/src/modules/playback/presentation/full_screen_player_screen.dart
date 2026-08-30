import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../shared/utils/duration_format.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../../video/presentation/video_detail_screen.dart';
import '../application/playback_providers.dart';
import '../data/player_system_adapter.dart';
import 'gif_editor_screen.dart';
import 'player_settings_screen.dart';
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

class _FullScreenPlayerScreenState extends ConsumerState<FullScreenPlayerScreen>
    with WidgetsBindingObserver {
  static const PlayerSystemAdapter _systemAdapter = PlayerSystemAdapter();
  final NativeVideoPlayerController _playerController =
      NativeVideoPlayerController();

  late String _currentVideoId;
  late int _currentPlaylistIndex;
  StreamSubscription<void>? _completedSubscription;
  Timer? _positionTimer;
  Timer? _controlsTimer;
  Timer? _adjustmentOverlayTimer;

  bool _canPop = false;
  bool _controlsLocked = false;
  bool _isSavingBeforePop = false;
  bool _isSubtitleEnabled = true;
  bool _isLandscape = false;
  bool _isPlaying = true;
  bool _isSeeking = false;
  bool _isZoomed = false;
  bool _backgroundPlaybackEnabled = false;
  bool _inPictureInPicture = false;
  bool _showControls = false;
  bool _showVideoSurface = true;
  double _playbackSpeed = 1;
  double? _appliedBrightness;
  double? _lastSettingsBrightness;
  double _mediaVolume = 0.5;
  _VerticalAdjustment? _verticalAdjustment;
  double? _verticalAdjustmentValue;
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
    WidgetsBinding.instance.addObserver(this);
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
    unawaited(_loadMediaVolume());
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _adjustmentOverlayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _positionTimer?.cancel();
    _completedSubscription?.cancel();
    unawaited(
      SystemChrome.setPreferredOrientations(
        const [DeviceOrientation.portraitUp],
      ),
    );
    unawaited(_systemAdapter.resetScreenBrightness().catchError((_) {}));
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(playbackVideoProvider(_currentVideoId));
    final appSettings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    _backgroundPlaybackEnabled = appSettings.backgroundPlayback;
    if (_lastSettingsBrightness != appSettings.videoBrightness) {
      _lastSettingsBrightness = appSettings.videoBrightness;
      _appliedBrightness = appSettings.videoBrightness;
      unawaited(_applyBrightness(appSettings.videoBrightness));
    }

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
                appSettings: appSettings,
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        !_backgroundPlaybackEnabled &&
        !_inPictureInPicture) {
      unawaited(_playerController.pause());
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
    if (state == AppLifecycleState.resumed) {
      _inPictureInPicture = false;
    }
  }

  Widget _buildVideoSurface({
    required Video video,
    required Duration resumePosition,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: Colors.black,
        child: _showVideoSurface
            ? NativeVideoPlayerView(
                key: ValueKey(video.id),
                controller: _playerController,
                uri: video.uri,
                initialPosition: _currentPosition > Duration.zero
                    ? _currentPosition
                    : resumePosition,
                subtitleUri: video.subtitleUri,
              )
            : const SizedBox.expand(),
      ),
    );
  }

  Widget _buildPlayerOverlay({
    required BuildContext context,
    required Video video,
    required AppSettings appSettings,
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
              child: _PlayerGestureListener(
                onTap: _toggleControlsVisibility,
                onHorizontalStart: _startDragSeek,
                onHorizontalUpdate: _updateDragSeek,
                onHorizontalEnd: () =>
                    unawaited(_finishDragSeek(displayDuration)),
                onVerticalStart: _startVerticalAdjustment,
                onVerticalUpdate: _updateVerticalAdjustment,
                onVerticalEnd: _finishVerticalAdjustment,
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
                    isSubtitleEnabled: _isSubtitleEnabled,
                    isLandscape: _isLandscape,
                    hasPrevious: _hasPrevious,
                    hasNext: _hasNext,
                    backgroundPlaybackEnabled: appSettings.backgroundPlayback,
                    showSpeedController: appSettings.showSpeedController,
                    playbackSpeed: _playbackSpeed,
                    positionText: formatDuration(
                      Duration(milliseconds: positionMs),
                    ),
                    durationText: formatDuration(displayDuration),
                    sliderValue: durationMs <= 0 ? 0 : positionMs.toDouble(),
                    sliderMax: durationMs <= 0 ? 1 : durationMs.toDouble(),
                    onDismiss: _toggleControlsVisibility,
                    onFlickSeekStart: _startDragSeek,
                    onFlickSeekUpdate: _updateDragSeek,
                    onFlickSeekEnd: () =>
                        unawaited(_finishDragSeek(displayDuration)),
                    onVerticalAdjustmentStart: _startVerticalAdjustment,
                    onVerticalAdjustmentUpdate: _updateVerticalAdjustment,
                    onVerticalAdjustmentEnd: _finishVerticalAdjustment,
                    onTogglePlayback: _isSavingBeforePop
                        ? null
                        : () => unawaited(_togglePlayback()),
                    onPrevious: _hasPrevious && !_isSavingBeforePop
                        ? () => unawaited(_playPrevious(video.id))
                        : null,
                    onNext: _hasNext && !_isSavingBeforePop
                        ? () => unawaited(_playNext(video.id))
                        : null,
                    onOpenSmartView: _isSavingBeforePop
                        ? null
                        : () => unawaited(_openSmartView()),
                    onOpenPopup: _isSavingBeforePop
                        ? null
                        : () => unawaited(_enterPictureInPicture()),
                    onCreateGif: _isSavingBeforePop
                        ? null
                        : () => unawaited(
                              _openGifEditor(video, displayDuration),
                            ),
                    onCaptureFrame: _isSavingBeforePop
                        ? null
                        : () => unawaited(_captureFrame(video)),
                    onToggleOrientation: _isSavingBeforePop
                        ? null
                        : () => unawaited(_toggleOrientation()),
                    onToggleResizeMode: _isSavingBeforePop
                        ? null
                        : () => unawaited(_toggleResizeMode()),
                    onChangeSpeed: _isSavingBeforePop
                        ? null
                        : () => unawaited(_showPlaybackSpeedController()),
                    onLock: _isSavingBeforePop ? null : _lockControls,
                    onToggleSubtitle:
                        video.subtitleUri != null && !_isSavingBeforePop
                            ? () => unawaited(_toggleSubtitle())
                            : null,
                    onOpenEditor: _isSavingBeforePop
                        ? null
                        : () => unawaited(_openEditor(video.id)),
                    onShare: _isSavingBeforePop
                        ? null
                        : () => unawaited(_shareVideo(video.id)),
                    onDelete: _isSavingBeforePop
                        ? null
                        : () => unawaited(_deleteVideo(video)),
                    onToggleBackgroundPlayback: _isSavingBeforePop
                        ? null
                        : () => unawaited(
                              _toggleBackgroundPlayback(appSettings),
                            ),
                    onOpenDetails: _isSavingBeforePop
                        ? null
                        : () => unawaited(_openDetails(video.id)),
                    onOpenSettings: _isSavingBeforePop
                        ? null
                        : () => unawaited(_openPlayerSettings()),
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
            if (_controlsLocked)
              Positioned(
                left: 18,
                bottom: 24,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    tooltip: 'ロック解除',
                    onPressed: _unlockControls,
                    icon: const Icon(Icons.lock_open),
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
            if (_verticalAdjustment case final adjustment?)
              Align(
                alignment: adjustment == _VerticalAdjustment.brightness
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _VerticalAdjustmentOverlay(
                    adjustment: adjustment,
                    value: _verticalAdjustmentValue ?? 0,
                  ),
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
    if (_controlsLocked) {
      return;
    }

    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _scheduleControlsAutoHide();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _scheduleControlsAutoHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _controlsLocked || !_showControls || _isSeeking) {
        return;
      }
      setState(() {
        _showControls = false;
      });
    });
  }

  void _lockControls() {
    _controlsTimer?.cancel();
    setState(() {
      _controlsLocked = true;
      _showControls = false;
    });
  }

  void _unlockControls() {
    setState(() {
      _controlsLocked = false;
      _showControls = true;
    });
    _scheduleControlsAutoHide();
  }

  Future<void> _toggleResizeMode() async {
    final nextZoomed = !_isZoomed;
    await _playerController.setResizeMode(nextZoomed ? 'zoom' : 'fit');
    if (mounted) {
      setState(() {
        _isZoomed = nextZoomed;
      });
      _scheduleControlsAutoHide();
    }
  }

  Future<void> _showPlaybackSpeedController() async {
    var selectedSpeed = _playbackSpeed;
    final speed = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF242529),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '再生速度',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${selectedSpeed.toStringAsFixed(2)}x',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                Slider(
                  min: 0.25,
                  max: 2,
                  divisions: 7,
                  value: selectedSpeed,
                  onChanged: (value) {
                    setSheetState(() {
                      selectedSpeed = value;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0.25x', style: TextStyle(color: Colors.white70)),
                    Text('2.0x', style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selectedSpeed),
                  child: const Text('完了'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (speed == null || !mounted) {
      _scheduleControlsAutoHide();
      return;
    }

    await _playerController.setPlaybackSpeed(speed);
    if (mounted) {
      setState(() {
        _playbackSpeed = speed;
      });
      _scheduleControlsAutoHide();
    }
  }

  void _startDragSeek() {
    if (_controlsLocked) {
      return;
    }

    setState(() {
      _isSeeking = true;
      _dragSeekStartPosition = _currentPosition;
      _dragSeekOffset = Duration.zero;
      _showControls = false;
    });

    unawaited(_refreshDragSeekStartPosition());
  }

  Future<void> _refreshDragSeekStartPosition() async {
    final position = await _playerController.currentPosition();
    if (!mounted || position == null) {
      return;
    }

    if (_isSeeking && _dragSeekOffset == Duration.zero) {
      setState(() {
        _dragSeekStartPosition = position;
      });
    }
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
    final settings = await ref.read(appSettingsProvider.future);

    if (settings.autoRepeat) {
      await _playerController.seekTo(Duration.zero);
      await _playerController.play();
      if (mounted) {
        setState(() {
          _currentPosition = Duration.zero;
          _isPlaying = true;
        });
      }
      return;
    }

    if (!settings.autoPlayNext || !_hasNext || !mounted) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
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
    _controlsTimer?.cancel();
    _isPlaying = true;
    _isSubtitleEnabled = true;
    _isSeeking = false;
    _isZoomed = false;
    _playbackSpeed = 1;
    _showControls = false;
    _controlsLocked = false;
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

  Future<void> _openEditor(String videoId) async {
    try {
      await ref.read(videoRepositoryProvider).openVideoInEditor(videoId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エディターを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _shareVideo(String videoId) async {
    try {
      await ref.read(videoRepositoryProvider).shareVideo(videoId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _deleteVideo(Video video) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除しますか？'),
        content: Text(video.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).deleteVideo(video.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _canPop = true;
      });
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _toggleBackgroundPlayback(AppSettings settings) async {
    await ref.read(updateSettingsUseCaseProvider).call(
          settings.copyWith(
            backgroundPlayback: !settings.backgroundPlayback,
          ),
        );
  }

  Future<void> _openDetails(String videoId) async {
    await _pushPlayerRoute(
      MaterialPageRoute<void>(
        builder: (_) => VideoDetailScreen(videoId: videoId),
      ),
    );
  }

  Future<void> _openPlayerSettings() async {
    await _pushPlayerRoute(
      MaterialPageRoute<void>(
        builder: (_) => const PlayerSettingsScreen(),
      ),
    );
  }

  Future<T?> _pushPlayerRoute<T>(Route<T> route) async {
    await _syncPlaybackState();
    final wasPlaying = await _playerController.isPlaying() ?? _isPlaying;
    await _playerController.pause();
    if (!mounted) return null;

    setState(() {
      _showVideoSurface = false;
      _showControls = false;
      _isPlaying = false;
    });

    final result = await Navigator.of(context).push(route);
    if (!mounted) return result;

    setState(() {
      _showVideoSurface = true;
      _isPlaying = wasPlaying;
    });
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return result;

    if (wasPlaying) {
      await _playerController.play();
    } else {
      await _playerController.pause();
    }
    return result;
  }

  Future<void> _applyBrightness(double value) async {
    try {
      await _systemAdapter.setScreenBrightness(value);
    } catch (_) {
      // Brightness control is Android-specific; playback remains available.
    }
  }

  Future<void> _loadMediaVolume() async {
    try {
      final volume = await _systemAdapter.getMediaVolume();
      if (mounted) {
        setState(() {
          _mediaVolume = volume;
        });
      }
    } catch (_) {
      // System volume is Android-specific. Keep a safe midpoint fallback.
    }
  }

  void _startVerticalAdjustment(bool adjustBrightness) {
    if (_controlsLocked) {
      return;
    }
    _controlsTimer?.cancel();
    _adjustmentOverlayTimer?.cancel();
    final adjustment = adjustBrightness
        ? _VerticalAdjustment.brightness
        : _VerticalAdjustment.volume;
    setState(() {
      _verticalAdjustment = adjustment;
      _verticalAdjustmentValue = adjustment == _VerticalAdjustment.brightness
          ? (_appliedBrightness ?? 0.5)
          : _mediaVolume;
    });
  }

  void _updateVerticalAdjustment(double deltaY) {
    final adjustment = _verticalAdjustment;
    final currentValue = _verticalAdjustmentValue;
    if (adjustment == null || currentValue == null || _controlsLocked) {
      return;
    }

    final height =
        MediaQuery.sizeOf(context).height.clamp(1.0, double.infinity);
    final value = (currentValue - deltaY / (height * 0.55)).clamp(0.0, 1.0);
    setState(() {
      _verticalAdjustmentValue = value;
      if (adjustment == _VerticalAdjustment.brightness) {
        _appliedBrightness = value;
      } else {
        _mediaVolume = value;
      }
    });

    if (adjustment == _VerticalAdjustment.brightness) {
      unawaited(_applyBrightness(value));
    } else {
      unawaited(_systemAdapter.setMediaVolume(value).catchError((_) {}));
    }
  }

  void _finishVerticalAdjustment() {
    if (_verticalAdjustment == null) {
      return;
    }
    _adjustmentOverlayTimer?.cancel();
    _adjustmentOverlayTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _verticalAdjustment = null;
        _verticalAdjustmentValue = null;
      });
      if (_showControls) {
        _scheduleControlsAutoHide();
      }
    });
  }

  Future<void> _openSmartView() async {
    try {
      await _systemAdapter.openCastSettings();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Smart Viewを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _enterPictureInPicture() async {
    try {
      setState(() {
        _showControls = false;
        _inPictureInPicture = true;
      });
      await _systemAdapter.enterPictureInPicture();
    } catch (error) {
      _inPictureInPicture = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ポップアッププレーヤーを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _captureFrame(Video video) async {
    try {
      final position =
          await _playerController.currentPosition() ?? _currentPosition;
      final savedUri = await _systemAdapter.captureFrame(
        videoUri: video.uri,
        position: position,
      );
      if (mounted && savedUri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フレームを保存しました')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('フレームを保存できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _openGifEditor(Video video, Duration duration) async {
    final position =
        await _playerController.currentPosition() ?? _currentPosition;
    await _playerController.pause();
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      _controlsTimer?.cancel();
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GifEditorScreen(
          video: video,
          initialPosition: position,
          videoDuration: duration,
        ),
      ),
    );
    if (mounted) {
      _scheduleControlsAutoHide();
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
    final position =
        await _playerController.currentPosition() ?? _currentPosition;
    if (position <= Duration.zero) {
      return;
    }

    await ref.read(savePlaybackPositionUseCaseProvider).call(
          videoId: videoId,
          position: position,
        );
  }
}

class _PlayerControlsOverlay extends StatelessWidget {
  static const _popupMenuColor = Color(0xFF3B3B3B);

  const _PlayerControlsOverlay({
    required this.video,
    required this.isLandscapeLayout,
    required this.isPlaying,
    required this.isSubtitleEnabled,
    required this.isLandscape,
    required this.hasPrevious,
    required this.hasNext,
    required this.backgroundPlaybackEnabled,
    required this.showSpeedController,
    required this.playbackSpeed,
    required this.positionText,
    required this.durationText,
    required this.sliderValue,
    required this.sliderMax,
    required this.onDismiss,
    required this.onTogglePlayback,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenSmartView,
    required this.onOpenPopup,
    required this.onCreateGif,
    required this.onCaptureFrame,
    required this.onToggleOrientation,
    required this.onToggleResizeMode,
    required this.onChangeSpeed,
    required this.onLock,
    required this.onToggleSubtitle,
    required this.onOpenEditor,
    required this.onShare,
    required this.onDelete,
    required this.onToggleBackgroundPlayback,
    required this.onOpenDetails,
    required this.onOpenSettings,
    required this.onSliderChangeStart,
    required this.onSliderChanged,
    required this.onSliderChangeEnd,
    required this.onFlickSeekStart,
    required this.onFlickSeekUpdate,
    required this.onFlickSeekEnd,
    required this.onVerticalAdjustmentStart,
    required this.onVerticalAdjustmentUpdate,
    required this.onVerticalAdjustmentEnd,
  });

  final Video video;
  final bool isLandscapeLayout;
  final bool isPlaying;
  final bool isSubtitleEnabled;
  final bool isLandscape;
  final bool hasPrevious;
  final bool hasNext;
  final bool backgroundPlaybackEnabled;
  final bool showSpeedController;
  final double playbackSpeed;
  final String positionText;
  final String durationText;
  final double sliderValue;
  final double sliderMax;
  final VoidCallback onDismiss;
  final VoidCallback? onTogglePlayback;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onOpenSmartView;
  final VoidCallback? onOpenPopup;
  final VoidCallback? onCreateGif;
  final VoidCallback? onCaptureFrame;
  final VoidCallback? onToggleOrientation;
  final VoidCallback? onToggleResizeMode;
  final VoidCallback? onChangeSpeed;
  final VoidCallback? onLock;
  final VoidCallback? onToggleSubtitle;
  final VoidCallback? onOpenEditor;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleBackgroundPlayback;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onOpenSettings;
  final ValueChanged<double>? onSliderChangeStart;
  final ValueChanged<double>? onSliderChanged;
  final ValueChanged<double>? onSliderChangeEnd;
  final VoidCallback onFlickSeekStart;
  final ValueChanged<double> onFlickSeekUpdate;
  final VoidCallback onFlickSeekEnd;
  final ValueChanged<bool> onVerticalAdjustmentStart;
  final ValueChanged<double> onVerticalAdjustmentUpdate;
  final VoidCallback onVerticalAdjustmentEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = isLandscapeLayout ? 4.0 : 8.0;
    final sidePadding = isLandscapeLayout ? 22.0 : 16.0;
    final bottomPadding = isLandscapeLayout ? 5.0 : 10.0;

    return _PlayerGestureListener(
      onHorizontalStart: onFlickSeekStart,
      onHorizontalUpdate: onFlickSeekUpdate,
      onHorizontalEnd: onFlickSeekEnd,
      onVerticalStart: onVerticalAdjustmentStart,
      onVerticalUpdate: onVerticalAdjustmentUpdate,
      onVerticalEnd: onVerticalAdjustmentEnd,
      onTap: onDismiss,
      child: ColoredBox(
        key: const ValueKey('player-controls-overlay'),
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
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
                        Expanded(
                          child: Text(
                            video.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Smart View',
                          child: SizedBox(
                            width: 48,
                            child: IconButton(
                              onPressed: onOpenSmartView,
                              color: Colors.white,
                              icon: const Icon(Icons.connected_tv_outlined),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: isSubtitleEnabled ? '字幕OFF' : '字幕ON',
                          child: SizedBox(
                            width: 42,
                            child: TextButton(
                              onPressed: onToggleSubtitle,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                minimumSize: const Size(40, 40),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('CC'),
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<_PlayerMenuAction>(
                          tooltip: 'その他',
                          iconColor: Colors.white,
                          color: _popupMenuColor,
                          surfaceTintColor: Colors.transparent,
                          constraints: const BoxConstraints.tightFor(
                            width: 168,
                          ),
                          menuPadding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          offset: const Offset(6, 0),
                          clipBehavior: Clip.antiAlias,
                          onSelected: (action) {
                            switch (action) {
                              case _PlayerMenuAction.editor:
                                onOpenEditor?.call();
                              case _PlayerMenuAction.delete:
                                onDelete?.call();
                              case _PlayerMenuAction.share:
                                onShare?.call();
                              case _PlayerMenuAction.backgroundPlayback:
                                onToggleBackgroundPlayback?.call();
                              case _PlayerMenuAction.details:
                                onOpenDetails?.call();
                              case _PlayerMenuAction.settings:
                                onOpenSettings?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: _PlayerMenuAction.editor,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text('エディター'),
                            ),
                            const PopupMenuItem(
                              value: _PlayerMenuAction.delete,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text('削除'),
                            ),
                            const PopupMenuItem(
                              value: _PlayerMenuAction.share,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text('共有'),
                            ),
                            if (video.audioCodec != null ||
                                video.audioChannelCount != null)
                              PopupMenuItem(
                                value: _PlayerMenuAction.backgroundPlayback,
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  backgroundPlaybackEnabled
                                      ? 'バックグラウンド再生OFF'
                                      : 'バックグラウンド再生ON',
                                ),
                              ),
                            const PopupMenuItem(
                              value: _PlayerMenuAction.details,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text('詳細'),
                            ),
                            const PopupMenuItem<_PlayerMenuAction>(
                              enabled: false,
                              height: 28,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: _DottedMenuDivider(),
                            ),
                            const PopupMenuItem(
                              value: _PlayerMenuAction.settings,
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text('設定'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: isLandscapeLayout ? 38 : 46,
                    child: Row(
                      children: [
                        Tooltip(
                          message: 'GIFを作成',
                          child: IconButton(
                            onPressed: onCreateGif,
                            color: Colors.white,
                            icon: const Icon(Icons.gif_box_outlined),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'ポップアッププレーヤー',
                          onPressed: onOpenPopup,
                          color: Colors.white,
                          iconSize: 22,
                          icon:
                              const Icon(Icons.picture_in_picture_alt_outlined),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'フレームをキャプチャ',
                        onPressed: onCaptureFrame,
                        color: Colors.white,
                        icon: const Icon(Icons.photo_camera_outlined),
                      ),
                      if (showSpeedController)
                        Tooltip(
                          message: '再生速度',
                          child: TextButton(
                            onPressed: onChangeSpeed,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(56, 42),
                            ),
                            child: Text(
                              '${playbackSpeed.toStringAsFixed(1)}x',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 56),
                      IconButton(
                        tooltip: '画面比率',
                        onPressed: onToggleResizeMode,
                        color: Colors.white,
                        icon: const Icon(Icons.fit_screen_outlined),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: const Color(0x667B8088),
                      thumbColor: Colors.white,
                      trackHeight: 1.5,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                    ),
                    child: Slider(
                      value: sliderValue.clamp(0, sliderMax),
                      max: sliderMax,
                      onChangeStart: onSliderChangeStart,
                      onChanged: onSliderChanged,
                      onChangeEnd: onSliderChangeEnd,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Text(
                          positionText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFD2D5D9),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          durationText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFD2D5D9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isLandscapeLayout ? 2 : 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        tooltip: 'ロック',
                        onPressed: onLock,
                        color: Colors.white,
                        icon: const Icon(Icons.lock_outline),
                      ),
                      IconButton(
                        tooltip: '前へ',
                        onPressed: hasPrevious ? onPrevious : null,
                        color: Colors.white,
                        disabledColor: const Color(0x667B8088),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        tooltip: isPlaying ? '一時停止' : '再生',
                        onPressed: onTogglePlayback,
                        color: Colors.white,
                        iconSize: 30,
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: '次へ',
                        onPressed: hasNext ? onNext : null,
                        color: Colors.white,
                        disabledColor: const Color(0x667B8088),
                        icon: const Icon(Icons.skip_next),
                      ),
                      IconButton(
                        tooltip: isLandscape ? '縦向き' : '横向き',
                        onPressed: onToggleOrientation,
                        color: Colors.white,
                        icon: const Icon(Icons.screen_rotation),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DottedMenuDivider extends StatelessWidget {
  const _DottedMenuDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey('player-menu-divider'),
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DottedMenuDividerPainter()),
    );
  }
}

class _DottedMenuDividerPainter extends CustomPainter {
  const _DottedMenuDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8A8A8A)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var x = 0.5; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 1, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerGestureListener extends StatefulWidget {
  const _PlayerGestureListener({
    required this.child,
    required this.onHorizontalStart,
    required this.onHorizontalUpdate,
    required this.onHorizontalEnd,
    required this.onVerticalStart,
    required this.onVerticalUpdate,
    required this.onVerticalEnd,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onHorizontalStart;
  final ValueChanged<double> onHorizontalUpdate;
  final VoidCallback onHorizontalEnd;
  final ValueChanged<bool> onVerticalStart;
  final ValueChanged<double> onVerticalUpdate;
  final VoidCallback onVerticalEnd;
  final VoidCallback onTap;

  @override
  State<_PlayerGestureListener> createState() => _PlayerGestureListenerState();
}

class _PlayerGestureListenerState extends State<_PlayerGestureListener> {
  Offset? _lastPosition;
  Offset? _downPosition;
  Offset? _localDownPosition;
  Size _gestureAreaSize = Size.zero;
  _GestureDirection? _gestureDirection;
  bool _ignorePointerSequence = false;

  static const _touchSlop = 18.0;
  static const _bottomControlGuard = 96.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final box = context.findRenderObject() as RenderBox?;
        final localPosition = box?.globalToLocal(event.position);
        final height = box?.size.height ?? 0;
        _localDownPosition = localPosition;
        _gestureAreaSize = box?.size ?? Size.zero;
        _ignorePointerSequence = localPosition != null &&
            height > 0 &&
            localPosition.dy >= height - _bottomControlGuard;
        _downPosition = event.position;
        _lastPosition = event.position;
        _gestureDirection = null;
      },
      onPointerMove: (event) {
        if (_ignorePointerSequence) {
          return;
        }

        final downPosition = _downPosition;
        final lastPosition = _lastPosition;
        if (downPosition == null || lastPosition == null) {
          return;
        }

        final totalDelta = event.position - downPosition;
        if (_gestureDirection == null) {
          final horizontal = totalDelta.dx.abs();
          final vertical = totalDelta.dy.abs();
          if (horizontal < _touchSlop && vertical < _touchSlop) {
            _lastPosition = event.position;
            return;
          }

          if (horizontal > vertical) {
            _gestureDirection = _GestureDirection.horizontal;
            widget.onHorizontalStart();
          } else {
            _gestureDirection = _GestureDirection.vertical;
            final localDownPosition = _localDownPosition;
            widget.onVerticalStart(
              localDownPosition != null &&
                  localDownPosition.dx < _gestureAreaSize.width / 2,
            );
          }
        }

        switch (_gestureDirection) {
          case _GestureDirection.horizontal:
            widget.onHorizontalUpdate(event.position.dx - lastPosition.dx);
          case _GestureDirection.vertical:
            widget.onVerticalUpdate(event.position.dy - lastPosition.dy);
          case null:
            break;
        }
        _lastPosition = event.position;
      },
      onPointerUp: (_) => _finishGesture(),
      onPointerCancel: (_) => _finishGesture(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child,
      ),
    );
  }

  void _finishGesture() {
    switch (_gestureDirection) {
      case _GestureDirection.horizontal:
        widget.onHorizontalEnd();
      case _GestureDirection.vertical:
        widget.onVerticalEnd();
      case null:
        break;
    }
    _lastPosition = null;
    _downPosition = null;
    _localDownPosition = null;
    _gestureAreaSize = Size.zero;
    _gestureDirection = null;
    _ignorePointerSequence = false;
  }
}

enum _GestureDirection { horizontal, vertical }

enum _VerticalAdjustment { brightness, volume }

class _VerticalAdjustmentOverlay extends StatelessWidget {
  const _VerticalAdjustmentOverlay({
    required this.adjustment,
    required this.value,
  });

  final _VerticalAdjustment adjustment;
  final double value;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0.0, 1.0);
    final percentage = (normalizedValue * 100).round();
    final isBrightness = adjustment == _VerticalAdjustment.brightness;
    final label = isBrightness ? '明るさ' : '音量';

    return Semantics(
      label: '$label $percentageパーセント',
      child: Container(
        key: ValueKey('${adjustment.name}-adjustment-overlay'),
        width: 64,
        height: 156,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xCC252525),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          children: [
            Icon(
              isBrightness
                  ? Icons.brightness_high_outlined
                  : percentage == 0
                      ? Icons.volume_off_outlined
                      : Icons.volume_up_outlined,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: const Color(0x667B8088),
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: normalizedValue,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
  editor,
  delete,
  share,
  backgroundPlayback,
  details,
  settings,
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
