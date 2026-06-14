import '../../video/domain/video.dart';
import 'playback_state.dart';

abstract interface class PlayerPort {
  Stream<PlaybackState> watchState();

  Future<void> open(Video video, {Duration? initialPosition});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);
}
