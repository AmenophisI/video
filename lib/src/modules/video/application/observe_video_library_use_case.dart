import '../domain/video.dart';
import '../domain/video_query.dart';
import '../domain/video_repository.dart';

class ObserveVideoLibraryUseCase {
  const ObserveVideoLibraryUseCase(this._repository);

  final VideoRepository _repository;

  Stream<List<Video>> call(VideoQuery query) {
    return _repository.watchVideos(query);
  }
}
