enum MediaPermissionStatus {
  unknown,
  granted,
  limited,
  denied,
}

class MediaPermissionState {
  const MediaPermissionState({
    required this.status,
    this.canRequestMore = false,
  });

  const MediaPermissionState.unknown()
      : status = MediaPermissionStatus.unknown,
        canRequestMore = false;

  final MediaPermissionStatus status;
  final bool canRequestMore;

  bool get canReadVideos =>
      status == MediaPermissionStatus.granted ||
      status == MediaPermissionStatus.limited;
}
