import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/playback/application/open_video_use_case.dart';
import 'package:video_player/src/modules/playback/application/save_playback_position_use_case.dart';
import 'package:video_player/src/modules/settings/domain/app_settings.dart';
import 'package:video_player/src/modules/settings/domain/settings_repository.dart';
import 'package:video_player/src/modules/video/domain/video.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';
import 'package:video_player/src/modules/video/domain/video_repository.dart';

void main() {
  group('OpenVideoUseCase', () {
    test('returns saved playback position when resume setting is enabled',
        () async {
      final repository = _FakeVideoRepository(_videoWithProgress());
      final useCase = OpenVideoUseCase(
        videoRepository: repository,
        settingsRepository: _FakeSettingsRepository(
          const AppSettings(rememberPlaybackPosition: true),
        ),
      );

      final video = await useCase('video-1');

      expect(video?.lastPlayedPosition, const Duration(minutes: 3));
      expect(video?.lastPlayedAt, isNotNull);
    });

    test('clears saved playback position when resume setting is disabled',
        () async {
      final repository = _FakeVideoRepository(_videoWithProgress());
      final useCase = OpenVideoUseCase(
        videoRepository: repository,
        settingsRepository: _FakeSettingsRepository(
          const AppSettings(rememberPlaybackPosition: false),
        ),
      );

      final video = await useCase('video-1');

      expect(video?.lastPlayedPosition, isNull);
      expect(video?.lastPlayedAt, isNull);
    });
  });

  group('SavePlaybackPositionUseCase', () {
    test('saves playback position when resume setting is enabled', () async {
      final repository = _FakeVideoRepository(_videoWithProgress());
      final useCase = SavePlaybackPositionUseCase(
        videoRepository: repository,
        settingsRepository: _FakeSettingsRepository(
          const AppSettings(rememberPlaybackPosition: true),
        ),
      );

      await useCase(
        videoId: 'video-1',
        position: const Duration(minutes: 5),
      );

      expect(repository.savedVideoId, 'video-1');
      expect(repository.savedPosition, const Duration(minutes: 5));
    });

    test('does not save playback position when resume setting is disabled',
        () async {
      final repository = _FakeVideoRepository(_videoWithProgress());
      final useCase = SavePlaybackPositionUseCase(
        videoRepository: repository,
        settingsRepository: _FakeSettingsRepository(
          const AppSettings(rememberPlaybackPosition: false),
        ),
      );

      await useCase(
        videoId: 'video-1',
        position: const Duration(minutes: 5),
      );

      expect(repository.savedVideoId, isNull);
      expect(repository.savedPosition, isNull);
    });
  });
}

Video _videoWithProgress() {
  return Video(
    id: 'video-1',
    mediaStoreId: 1,
    uri: Uri.parse('content://media/external/video/media/1'),
    displayName: 'sample.mp4',
    folderId: 'download',
    folderName: 'Download',
    duration: const Duration(minutes: 10),
    lastPlayedPosition: const Duration(minutes: 3),
    lastPlayedAt: DateTime(2026, 1, 1),
  );
}

class _FakeSettingsRepository implements SettingsRepository {
  const _FakeSettingsRepository(this.settings);

  final AppSettings settings;

  @override
  Stream<AppSettings> watchSettings() => Stream.value(settings);

  @override
  Future<void> updateSettings(AppSettings settings) async {}
}

class _FakeVideoRepository implements VideoRepository {
  _FakeVideoRepository(this.video);

  final Video video;
  String? savedVideoId;
  Duration? savedPosition;

  @override
  Future<Video?> getVideo(String id) async {
    return id == video.id ? video : null;
  }

  @override
  Future<void> updatePlaybackPosition({
    required String videoId,
    required Duration position,
  }) async {
    savedVideoId = videoId;
    savedPosition = position;
  }

  @override
  Stream<List<Video>> watchVideos(VideoQuery query) => Stream.value([video]);

  @override
  Future<void> addSearchHistory(String keyword) async {}

  @override
  Future<void> clearSearchHistory() async {}

  @override
  Future<void> copyVideo({
    required String videoId,
    required String relativePath,
    String? displayName,
  }) async {}

  @override
  Future<void> deleteVideo(String videoId) async {}

  @override
  Future<void> deleteVideos(List<String> videoIds) async {}

  @override
  Future<List<String>> getSearchHistory() async => const [];

  @override
  Future<void> moveVideo({
    required String videoId,
    required String relativePath,
  }) async {}

  @override
  Future<void> openVideoInEditor(String videoId) async {}

  @override
  Future<void> openVideoInExternalPlayer(String videoId) async {}

  @override
  Future<void> refreshIndex() async {}

  @override
  Future<void> renameVideo({
    required String videoId,
    required String displayName,
  }) async {}

  @override
  Future<void> setFavorite({
    required String videoId,
    required bool isFavorite,
  }) async {}

  @override
  Future<void> setPrivate({
    required String videoId,
    required bool isPrivate,
  }) async {}

  @override
  Future<void> shareVideo(String videoId) async {}

  @override
  Future<void> shareVideos(List<String> videoIds) async {}

  @override
  Future<void> moveToSecureFolder(List<String> videoIds) async {}
}
