import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';

void main() {
  test('setPrivate hides a video and moves it to the private path', () async {
    final repository = InMemoryVideoRepository.seeded();

    await repository.setPrivate(videoId: 'video-001', isPrivate: true);

    final publicVideos = await repository.watchVideos(const VideoQuery()).first;
    final privateVideos = await repository
        .watchVideos(const VideoQuery(filter: VideoFilter.privateVideos))
        .first;

    expect(publicVideos.map((video) => video.id), isNot(contains('video-001')));
    expect(privateVideos.map((video) => video.id), contains('video-001'));
    expect(
      privateVideos.firstWhere((video) => video.id == 'video-001').relativePath,
      'Movies/VideoLibraryPrivate/',
    );

    repository.dispose();
  });
}
