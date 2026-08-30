import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:video_player/src/modules/media_access/data/file_operations/file_operation_adapter.dart';
import 'package:video_player/src/modules/media_access/data/media_store/media_store_adapter.dart';
import 'package:video_player/src/modules/media_access/data/media_store/media_store_video_dto.dart';
import 'package:video_player/src/modules/media_access/data/permissions/media_permission_adapter.dart';
import 'package:video_player/src/modules/media_access/domain/media_permission.dart';
import 'package:video_player/src/modules/playback/data/shared_preferences_playback_position_store.dart';
import 'package:video_player/src/modules/video/data/repositories/media_store_video_repository.dart';
import 'package:video_player/src/modules/video/data/video_metadata_store.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';
import 'package:video_player/src/shared/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('renameVideo updates the cached index entry', () async {
    final mediaStore = _FakeMediaStoreAdapter([_dto()]);
    final repository = _repository(mediaStore: mediaStore);
    addTearDown(repository.dispose);

    await repository.refreshIndex();
    await repository.renameVideo(videoId: '1', displayName: 'renamed.mp4');

    final videos = await repository.watchVideos(const VideoQuery()).first;
    expect(videos.single.displayName, 'renamed.mp4');
  });

  test('moveVideo refreshes the index from MediaStore', () async {
    final mediaStore = _FakeMediaStoreAdapter([_dto()]);
    final fileOperations = _FakeFileOperationAdapter(
      onMove: ({required uri, required relativePath}) {
        mediaStore.videos = [
          _dto(
            relativePath: relativePath,
            folderId: 'moved',
            folderName: 'Moved',
          ),
        ];
      },
    );
    final repository = _repository(
      mediaStore: mediaStore,
      fileOperations: fileOperations,
    );
    addTearDown(repository.dispose);

    await repository.refreshIndex();
    await repository.moveVideo(videoId: '1', relativePath: 'Movies/Moved/');

    final videos = await repository.watchVideos(const VideoQuery()).first;
    expect(videos.single.relativePath, 'Movies/Moved/');
    expect(videos.single.folderName, 'Moved');
  });

  test('copyVideo refreshes the index and includes the copied item', () async {
    final mediaStore = _FakeMediaStoreAdapter([_dto()]);
    final fileOperations = _FakeFileOperationAdapter(
      onCopy: ({
        required uri,
        required displayName,
        required relativePath,
        required mimeType,
      }) {
        mediaStore.videos = [
          _dto(),
          _dto(
            mediaStoreId: 2,
            displayName: displayName,
            relativePath: relativePath,
            folderId: 'copies',
            folderName: 'Copies',
          ),
        ];
      },
    );
    final repository = _repository(
      mediaStore: mediaStore,
      fileOperations: fileOperations,
    );
    addTearDown(repository.dispose);

    await repository.refreshIndex();
    await repository.copyVideo(
      videoId: '1',
      relativePath: 'Movies/Copies/',
      displayName: 'sample-copy.mp4',
    );

    final videos = await repository.watchVideos(const VideoQuery()).first;
    expect(videos, hasLength(2));
    expect(
      videos.map((video) => video.displayName),
      contains('sample-copy.mp4'),
    );
  });

  test('deleteVideo removes the video from memory and database index',
      () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = _repository(
      mediaStore: _FakeMediaStoreAdapter([_dto()]),
      database: database,
    );
    addTearDown(repository.dispose);

    await repository.refreshIndex();
    expect(await database.getVideoIndexEntries(), hasLength(1));

    await repository.deleteVideo('1');

    expect(await repository.watchVideos(const VideoQuery()).first, isEmpty);
    expect(await database.getVideoIndexEntries(), isEmpty);
  });

  test('codec metadata survives refresh and database cache restore', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final firstRepository = _repository(
      mediaStore: _FakeMediaStoreAdapter([
        _dto(
          videoCodec: 'video/avc',
          audioCodec: 'audio/mp4a-latm',
          audioChannelCount: 2,
        ),
      ]),
      database: database,
    );

    await firstRepository.refreshIndex();
    final refreshed =
        (await firstRepository.watchVideos(const VideoQuery()).first).single;
    expect(refreshed.videoCodec, 'video/avc');
    expect(refreshed.audioCodec, 'audio/mp4a-latm');
    expect(refreshed.audioChannelCount, 2);
    final cachedRepository = _repository(
      mediaStore: _FakeMediaStoreAdapter([
        _dto(
          videoCodec: 'video/avc',
          audioCodec: 'audio/mp4a-latm',
          audioChannelCount: 2,
        ),
      ]),
      database: database,
    );
    addTearDown(firstRepository.dispose);
    addTearDown(cachedRepository.dispose);
    final cached =
        (await cachedRepository.watchVideos(const VideoQuery()).first).single;
    expect(cached.videoCodec, 'video/avc');
    expect(cached.audioCodec, 'audio/mp4a-latm');
    expect(cached.audioChannelCount, 2);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
}

MediaStoreVideoRepository _repository({
  required _FakeMediaStoreAdapter mediaStore,
  _FakeFileOperationAdapter? fileOperations,
  AppDatabase? database,
}) {
  return MediaStoreVideoRepository(
    mediaStoreAdapter: mediaStore,
    permissionAdapter: const _GrantedPermissionAdapter(),
    fileOperationAdapter: fileOperations ?? const _FakeFileOperationAdapter(),
    playbackPositionStore: _EmptyPlaybackPositionStore(),
    metadataStore: _EmptyVideoMetadataStore(),
    database: database ?? AppDatabase.forTesting(NativeDatabase.memory()),
  );
}

MediaStoreVideoDto _dto({
  int mediaStoreId = 1,
  String displayName = 'sample.mp4',
  String relativePath = 'Download/',
  String folderId = 'download',
  String folderName = 'Download',
  String? videoCodec,
  String? audioCodec,
  int? audioChannelCount,
}) {
  return MediaStoreVideoDto(
    mediaStoreId: mediaStoreId,
    uri: Uri.parse('content://media/external/video/media/$mediaStoreId'),
    displayName: displayName,
    folderId: folderId,
    folderName: folderName,
    relativePath: relativePath,
    mimeType: 'video/mp4',
    durationMs: 1000,
    sizeBytes: 49962,
    modifiedAtMs: DateTime(2026, 6, 14).millisecondsSinceEpoch,
    isPlayable: true,
    videoCodec: videoCodec,
    audioCodec: audioCodec,
    audioChannelCount: audioChannelCount,
  );
}

class _FakeMediaStoreAdapter extends MediaStoreAdapter {
  _FakeMediaStoreAdapter(this.videos);

  List<MediaStoreVideoDto> videos;

  @override
  Future<List<MediaStoreVideoDto>> queryVideos() async {
    return videos;
  }
}

class _GrantedPermissionAdapter extends MediaPermissionAdapter {
  const _GrantedPermissionAdapter();

  @override
  Future<MediaPermission> checkPermission() async {
    return MediaPermission.granted;
  }

  @override
  Future<MediaPermission> requestPermission() async {
    return MediaPermission.granted;
  }
}

class _FakeFileOperationAdapter extends FileOperationAdapter {
  const _FakeFileOperationAdapter({
    this.onMove,
    this.onCopy,
  });

  final void Function({
    required Uri uri,
    required String relativePath,
  })? onMove;
  final void Function({
    required Uri uri,
    required String displayName,
    required String relativePath,
    required String? mimeType,
  })? onCopy;

  @override
  Future<void> delete(Uri uri) async {}

  @override
  Future<void> rename({
    required Uri uri,
    required String displayName,
  }) async {}

  @override
  Future<void> move({
    required Uri uri,
    required String relativePath,
  }) async {
    onMove?.call(uri: uri, relativePath: relativePath);
  }

  @override
  Future<void> copy({
    required Uri uri,
    required String displayName,
    required String relativePath,
    String? mimeType,
  }) async {
    onCopy?.call(
      uri: uri,
      displayName: displayName,
      relativePath: relativePath,
      mimeType: mimeType,
    );
  }
}

class _EmptyPlaybackPositionStore
    extends SharedPreferencesPlaybackPositionStore {
  @override
  Future<Map<String, SavedPlaybackPosition>> getPositions(
    Iterable<String> videoIds,
  ) async {
    return const {};
  }
}

class _EmptyVideoMetadataStore extends VideoMetadataStore {
  @override
  Future<VideoMetadata> loadMetadata() async {
    return const VideoMetadata(
      favoriteVideoIds: {},
      privateVideoIds: {},
      privateOriginalPaths: {},
    );
  }
}
