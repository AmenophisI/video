import '../domain/video.dart';
import '../domain/video_query.dart';

class VideoLibraryState {
  const VideoLibraryState({
    required this.videos,
    required this.query,
  });

  final List<Video> videos;
  final VideoQuery query;
}
