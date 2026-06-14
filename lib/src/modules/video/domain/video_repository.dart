import 'video.dart';
import 'video_query.dart';

abstract interface class VideoRepository {
  Stream<List<Video>> watchVideos(VideoQuery query);

  Future<Video?> getVideo(String id);

  Future<void> refreshIndex();

  Future<void> updatePlaybackPosition({
    required String videoId,
    required Duration position,
  });

  Future<void> shareVideo(String videoId);

  Future<void> shareVideos(List<String> videoIds);

  Future<void> openVideoInEditor(String videoId);

  Future<void> openVideoInExternalPlayer(String videoId);

  Future<void> deleteVideo(String videoId);

  Future<void> deleteVideos(List<String> videoIds);

  Future<void> renameVideo({
    required String videoId,
    required String displayName,
  });

  Future<void> moveVideo({
    required String videoId,
    required String relativePath,
  });

  Future<void> copyVideo({
    required String videoId,
    required String relativePath,
    String? displayName,
  });

  Future<void> setFavorite({
    required String videoId,
    required bool isFavorite,
  });

  Future<void> setPrivate({
    required String videoId,
    required bool isPrivate,
  });

  Future<void> addSearchHistory(String keyword);

  Future<List<String>> getSearchHistory();

  Future<void> clearSearchHistory();
}
