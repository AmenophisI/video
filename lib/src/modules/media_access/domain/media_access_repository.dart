import 'media_permission.dart';

abstract interface class MediaAccessRepository {
  Future<MediaPermission> checkPermission();

  Future<MediaPermission> requestPermission();
}
