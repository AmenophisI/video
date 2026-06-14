enum MediaPermission {
  unknown,
  granted,
  limited,
  denied,
}

extension MediaPermissionX on MediaPermission {
  bool get canReadVideos {
    return this == MediaPermission.granted || this == MediaPermission.limited;
  }
}
