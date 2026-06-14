import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/media_access/data/media_store/media_store_video_dto.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/domain/video.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';

void main() {
  test('Video tags include Hyperlapse when hyperlapse is detected', () {
    final video = Video(
      id: '1',
      mediaStoreId: 1,
      uri: Uri.parse('content://media/external/video/media/1'),
      displayName: 'Hyperlapse_駅前.mp4',
      folderId: 'camera',
      folderName: 'Camera',
      isHyperlapse: true,
    );

    expect(video.tags, contains('Hyperlapse'));
  });

  test('Video tags include HDR when HDR metadata is detected', () {
    final video = Video(
      id: 'hdr',
      mediaStoreId: 2,
      uri: Uri.parse('content://media/external/video/media/2'),
      displayName: 'sample.mp4',
      folderId: 'camera',
      folderName: 'Camera',
      isHdr: true,
    );

    expect(video.tags, contains('HDR'));
  });

  test('Video tags include DRM when DRM metadata is detected', () {
    final video = Video(
      id: 'drm',
      mediaStoreId: 3,
      uri: Uri.parse('content://media/external/video/media/3'),
      displayName: 'protected.mp4',
      folderId: 'download',
      folderName: 'Download',
      isDrm: true,
    );

    expect(video.tags, contains('DRM'));
  });

  test('DRM videos expose a playback unavailable reason', () {
    final video = Video(
      id: 'drm-unplayable',
      mediaStoreId: 30,
      uri: Uri.parse('content://media/external/video/media/30'),
      displayName: 'protected.mp4',
      folderId: 'download',
      folderName: 'Download',
      isDrm: true,
      isPlayable: false,
    );

    expect(video.playbackUnavailableReason, contains('DRM保護'));
  });

  test('MediaStoreVideoDto parses DRM metadata from platform map', () {
    final dto = MediaStoreVideoDto.fromMap({
      'mediaStoreId': 4,
      'uri': 'content://media/external/video/media/4',
      'displayName': 'protected.mp4',
      'folderId': 'download',
      'folderName': 'Download',
      'isDrm': true,
    });

    expect(dto.isDrm, isTrue);
  });

  test('MediaStoreVideoDto parses supplemental metadata text', () {
    final dto = MediaStoreVideoDto.fromMap({
      'mediaStoreId': 5,
      'uri': 'content://media/external/video/media/5',
      'displayName': 'clip.mp4',
      'folderId': 'camera',
      'folderName': 'Camera',
      'metadataText': 'spherical equirectangular video',
    });

    expect(dto.metadataText, contains('spherical'));
  });

  test('InMemoryVideoRepository can filter hyperlapse videos', () async {
    final repository = InMemoryVideoRepository.seeded();

    final videos = await repository
        .watchVideos(const VideoQuery(filter: VideoFilter.hyperlapse))
        .first;

    expect(videos, hasLength(1));
    expect(videos.single.isHyperlapse, isTrue);
    expect(videos.single.displayName, contains('Hyperlapse'));

    repository.dispose();
  });
}
