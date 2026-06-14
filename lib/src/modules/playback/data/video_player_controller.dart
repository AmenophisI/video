import 'dart:async';

import '../../video/domain/video.dart';
import '../domain/playback_state.dart';
import '../domain/player_port.dart';

class VideoPlayerController implements PlayerPort {
  final StreamController<PlaybackState> _controller =
      StreamController<PlaybackState>.broadcast();

  PlaybackState _state = const PlaybackState();

  @override
  Stream<PlaybackState> watchState() async* {
    yield _state;
    yield* _controller.stream;
  }

  @override
  Future<void> open(Video video, {Duration? initialPosition}) async {
    _setState(
      PlaybackState(
        status: PlaybackStatus.paused,
        position: initialPosition ?? Duration.zero,
        duration: video.duration,
      ),
    );
  }

  @override
  Future<void> play() async {
    _setState(
      PlaybackState(
        status: PlaybackStatus.playing,
        position: _state.position,
        duration: _state.duration,
      ),
    );
  }

  @override
  Future<void> pause() async {
    _setState(
      PlaybackState(
        status: PlaybackStatus.paused,
        position: _state.position,
        duration: _state.duration,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    _setState(
      PlaybackState(
        status: _state.status,
        position: position,
        duration: _state.duration,
      ),
    );
  }

  void dispose() {
    _controller.close();
  }

  void _setState(PlaybackState state) {
    _state = state;
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }
}
