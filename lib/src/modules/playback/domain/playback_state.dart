enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  ended,
  failed,
}

class PlaybackState {
  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration,
  });

  final PlaybackStatus status;
  final Duration position;
  final Duration? duration;
}
