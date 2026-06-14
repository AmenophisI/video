import '../../video/domain/video.dart';
import '../../video/domain/video_query.dart';
import '../../video/domain/video_repository.dart';

class ObserveFolderVideosUseCase {
  const ObserveFolderVideosUseCase(this._videoRepository);

  final VideoRepository _videoRepository;

  Stream<List<Video>> call(String folderId) {
    return _videoRepository.watchVideos(VideoQuery(folderId: folderId));
  }
}
