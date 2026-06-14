import '../domain/video_repository.dart';

class ScanVideosUseCase {
  const ScanVideosUseCase(this._repository);

  final VideoRepository _repository;

  Future<void> call() {
    return _repository.refreshIndex();
  }
}
