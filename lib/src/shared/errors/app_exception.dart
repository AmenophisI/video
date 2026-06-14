sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message);
}

class MediaAccessException extends AppException {
  const MediaAccessException(super.message);
}

class PlaybackException extends AppException {
  const PlaybackException(super.message);
}
