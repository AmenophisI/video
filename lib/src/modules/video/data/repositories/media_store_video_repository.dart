import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../../../../shared/database/app_database.dart';
import '../../../../shared/errors/app_exception.dart';
import '../../../media_access/data/file_operations/file_operation_adapter.dart';
import '../../../media_access/data/media_store/media_store_adapter.dart';
import '../../../media_access/data/media_store/media_store_video_dto.dart';
import '../../../media_access/data/permissions/media_permission_adapter.dart';
import '../../../media_access/data/thumbnails/thumbnail_cache.dart';
import '../../../media_access/domain/media_permission.dart';
import '../../../playback/data/shared_preferences_playback_position_store.dart';
import '../video_metadata_store.dart';
import '../../domain/video.dart';
import '../../domain/video_query.dart';
import '../../domain/video_repository.dart';

class MediaStoreVideoRepository implements VideoRepository {
  MediaStoreVideoRepository({
    required MediaStoreAdapter mediaStoreAdapter,
    required MediaPermissionAdapter permissionAdapter,
    FileOperationAdapter? fileOperationAdapter,
    SharedPreferencesPlaybackPositionStore? playbackPositionStore,
    VideoMetadataStore? metadataStore,
    AppDatabase? database,
  })  : _mediaStoreAdapter = mediaStoreAdapter,
        _permissionAdapter = permissionAdapter,
        _fileOperationAdapter =
            fileOperationAdapter ?? const FileOperationAdapter(),
        _playbackPositionStore =
            playbackPositionStore ?? SharedPreferencesPlaybackPositionStore(),
        _metadataStore = metadataStore ?? VideoMetadataStore(),
        _database = database ?? AppDatabase();

  final MediaStoreAdapter _mediaStoreAdapter;
  final MediaPermissionAdapter _permissionAdapter;
  final FileOperationAdapter _fileOperationAdapter;
  final SharedPreferencesPlaybackPositionStore _playbackPositionStore;
  final VideoMetadataStore _metadataStore;
  final AppDatabase _database;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  List<Video> _videos = const [];
  bool _hasLoaded = false;

  @override
  Stream<List<Video>> watchVideos(VideoQuery query) async* {
    if (!_hasLoaded) {
      await _loadCachedIndex();
      unawaited(refreshIndex());
    }

    yield _applyQuery(query);
    yield* _controller.stream.map((_) => _applyQuery(query));
  }

  @override
  Future<Video?> getVideo(String id) async {
    if (!_hasLoaded) {
      await refreshIndex();
    }

    for (final video in _videos) {
      if (video.id == id) {
        return video;
      }
    }

    return null;
  }

  @override
  Future<void> refreshIndex() async {
    var permission = await _permissionAdapter.checkPermission();
    if (!permission.canReadVideos) {
      permission = await _permissionAdapter.requestPermission();
    }

    if (!permission.canReadVideos) {
      _videos = const [];
      _hasLoaded = true;
      _emit();
      return;
    }

    final previousVideosById = {
      for (final video in _videos) video.id: video,
    };
    final List<MediaStoreVideoDto> videos;
    try {
      videos = await _mediaStoreAdapter.queryVideos();
    } catch (_) {
      _hasLoaded = true;
      _emit();
      return;
    }
    final savedPositions = await _playbackPositionStore.getPositions(
      videos.map((dto) => dto.mediaStoreId.toString()),
    );
    final metadata = await _metadataStore.loadMetadata();

    _videos = videos.map((dto) {
      final next = _toVideo(dto);
      final previous = previousVideosById[next.id];
      final savedPosition = savedPositions[next.id];
      final withMetadata = next.copyWith(
        isFavorite: metadata.favoriteVideoIds.contains(next.id),
        isPrivate: metadata.privateVideoIds.contains(next.id),
      );

      if (previous == null) {
        if (savedPosition != null) {
          return withMetadata.copyWith(
            lastPlayedPosition: savedPosition.position,
            lastPlayedAt: savedPosition.playedAt,
          );
        }

        return withMetadata;
      }

      return withMetadata.copyWith(
        lastPlayedPosition:
            savedPosition?.position ?? previous.lastPlayedPosition,
        lastPlayedAt: savedPosition?.playedAt ?? previous.lastPlayedAt,
      );
    }).toList(growable: false);
    await _database.replaceVideoIndexEntries(_videos.map(_toEntry).toList());
    _hasLoaded = true;
    _emit();
  }

  @override
  Future<void> updatePlaybackPosition({
    required String videoId,
    required Duration position,
  }) async {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) {
      return;
    }

    final playedAt = DateTime.now();

    await _playbackPositionStore.savePosition(
      videoId: videoId,
      position: position,
      playedAt: playedAt,
    );

    _videos = [
      ..._videos.take(index),
      _videos[index].copyWith(
        lastPlayedPosition: position,
        lastPlayedAt: playedAt,
      ),
      ..._videos.skip(index + 1),
    ];
    await _database.updateVideoIndexEntry(_toEntry(_videos[index]));
    _emit();
  }

  @override
  Future<void> shareVideo(String videoId) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(() => _fileOperationAdapter.share(video.uri));
  }

  @override
  Future<void> shareVideos(List<String> videoIds) async {
    final videosById = {
      for (final video in _videos) video.id: video,
    };
    final uris = [
      for (final id in videoIds)
        if (videosById[id] != null) videosById[id]!.uri,
    ];
    if (uris.isEmpty) {
      return;
    }

    if (uris.length == 1) {
      await _runFileOperation(() => _fileOperationAdapter.share(uris.single));
      return;
    }

    await _runFileOperation(() => _fileOperationAdapter.shareMultiple(uris));
  }

  @override
  Future<void> moveToSecureFolder(List<String> videoIds) async {
    final videosById = {
      for (final video in _videos) video.id: video,
    };
    final uris = [
      for (final id in videoIds)
        if (videosById[id] != null) videosById[id]!.uri,
    ];
    if (uris.isEmpty) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.moveToSecureFolder(uris),
    );
  }

  @override
  Future<void> openVideoInEditor(String videoId) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.openEditor(video.uri),
    );
  }

  @override
  Future<void> openVideoInExternalPlayer(String videoId) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.openExternalPlayer(video.uri),
    );
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(() => _fileOperationAdapter.delete(video.uri));
    _videos =
        _videos.where((item) => item.id != videoId).toList(growable: false);
    await _database.deleteVideoIndexEntry(videoId);
    _emit();
  }

  @override
  Future<void> deleteVideos(List<String> videoIds) async {
    final targetIds = videoIds.toSet();
    final targetVideos = [
      for (final video in _videos)
        if (targetIds.contains(video.id)) video,
    ];
    if (targetVideos.isEmpty) {
      return;
    }

    if (targetVideos.length == 1) {
      await deleteVideo(targetVideos.single.id);
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.deleteMultiple(
        targetVideos.map((video) => video.uri).toList(growable: false),
      ),
    );
    _videos = _videos.where((video) => !targetIds.contains(video.id)).toList();
    await Future.wait([
      for (final video in targetVideos)
        _database.deleteVideoIndexEntry(video.id),
    ]);
    _emit();
  }

  @override
  Future<void> renameVideo({
    required String videoId,
    required String displayName,
  }) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.rename(
        uri: video.uri,
        displayName: displayName,
      ),
    );

    final index = _videos.indexWhere((item) => item.id == videoId);
    if (index == -1) {
      return;
    }

    _videos = [
      ..._videos.take(index),
      _videos[index].copyWith(displayName: displayName),
      ..._videos.skip(index + 1),
    ];
    await _database.updateVideoIndexEntry(_toEntry(_videos[index]));
    _emit();
  }

  @override
  Future<void> moveVideo({
    required String videoId,
    required String relativePath,
  }) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.move(
        uri: video.uri,
        relativePath: relativePath,
      ),
    );
    await refreshIndex();
  }

  @override
  Future<void> copyVideo({
    required String videoId,
    required String relativePath,
    String? displayName,
  }) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    await _runFileOperation(
      () => _fileOperationAdapter.copy(
        uri: video.uri,
        displayName: displayName ?? video.displayName,
        relativePath: relativePath,
        mimeType: video.mimeType,
      ),
    );
    await refreshIndex();
  }

  @override
  Future<void> setFavorite({
    required String videoId,
    required bool isFavorite,
  }) async {
    await _metadataStore.setFavorite(
      videoId: videoId,
      isFavorite: isFavorite,
    );
    _replaceVideo(videoId, (video) => video.copyWith(isFavorite: isFavorite));
  }

  @override
  Future<void> setPrivate({
    required String videoId,
    required bool isPrivate,
  }) async {
    final video = await getVideo(videoId);
    if (video == null) {
      return;
    }

    if (isPrivate) {
      final originalPath = _privateRestorePath(video.relativePath);
      await _runFileOperation(
        () => _fileOperationAdapter.move(
          uri: video.uri,
          relativePath: _privateRelativePath,
        ),
      );
      await _metadataStore.setPrivateOriginalPath(
        videoId: videoId,
        relativePath: originalPath,
      );
    } else {
      final restorePath =
          await _metadataStore.getPrivateOriginalPath(videoId) ??
              _defaultRestorePath;
      await _runFileOperation(
        () => _fileOperationAdapter.move(
          uri: video.uri,
          relativePath: restorePath,
        ),
      );
      await _metadataStore.setPrivateOriginalPath(
        videoId: videoId,
        relativePath: null,
      );
    }

    await _metadataStore.setPrivate(videoId: videoId, isPrivate: isPrivate);
    if (isPrivate) {
      await const ThumbnailCache().remove(videoId);
    }
    await refreshIndex();
  }

  @override
  Future<void> addSearchHistory(String keyword) {
    return _metadataStore.addSearchHistory(keyword);
  }

  @override
  Future<List<String>> getSearchHistory() {
    return _metadataStore.loadSearchHistory();
  }

  @override
  Future<void> clearSearchHistory() {
    return _metadataStore.clearSearchHistory();
  }

  void dispose() {
    _controller.close();
    _database.close();
  }

  Future<void> _runFileOperation(Future<void> Function() operation) async {
    try {
      await operation();
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  AppException _mapPlatformException(PlatformException error) {
    return switch (error.code) {
      'insufficient_storage' => const MediaAccessException(
          '端末の空き容量が不足しています。不要なファイルを削除してからもう一度お試しください。',
        ),
      'delete_cancelled' || 'write_cancelled' => const MediaAccessException(
          '操作がキャンセルされました。',
        ),
      'editor_not_found' => const MediaAccessException(
          'この動画を開ける編集アプリが見つかりません。',
        ),
      'player_not_found' => const PlaybackException(
          'この動画を開ける外部プレイヤーが見つかりません。',
        ),
      'share_failed' => const MediaAccessException(
          '共有を開始できませんでした。',
        ),
      'rename_failed' => const MediaAccessException(
          '名前を変更できませんでした。別のアプリで使用中、または書き込み権限がない可能性があります。',
        ),
      'move_failed' => const MediaAccessException(
          '動画を移動できませんでした。保存先が利用できるか確認してください。',
        ),
      'copy_failed' => const MediaAccessException(
          '動画をコピーできませんでした。保存先や空き容量を確認してください。',
        ),
      'delete_failed' => const MediaAccessException(
          '動画を削除できませんでした。権限またはファイルの状態を確認してください。',
        ),
      'unsupported_version' => const MediaAccessException(
          'このAndroidバージョンでは、この操作を利用できません。',
        ),
      _ => MediaAccessException(
          error.message?.isNotEmpty == true ? error.message! : 'ファイル操作に失敗しました。',
        ),
    };
  }

  Future<void> _loadCachedIndex() async {
    try {
      final rows = await _database.getVideoIndexEntries();
      _videos = rows.map(_fromEntry).toList(growable: false);
    } catch (_) {
      _videos = const [];
      await _database.clearVideoIndexEntries();
    }
    _hasLoaded = true;
    _emit();
  }

  Video _toVideo(MediaStoreVideoDto dto) {
    return Video(
      id: dto.mediaStoreId.toString(),
      mediaStoreId: dto.mediaStoreId,
      uri: dto.uri,
      displayName: dto.displayName,
      folderId: dto.folderId,
      folderName: dto.folderName,
      relativePath: dto.relativePath,
      mimeType: dto.mimeType,
      duration: _durationFromMs(dto.durationMs),
      sizeBytes: dto.sizeBytes,
      width: dto.width,
      height: dto.height,
      rotationDegrees: dto.rotationDegrees,
      bitrate: dto.bitrate,
      frameRate: dto.frameRate,
      videoCodec: dto.videoCodec,
      audioCodec: dto.audioCodec,
      audioChannelCount: dto.audioChannelCount,
      subtitleUri: dto.subtitleUri,
      createdAt: _dateTimeFromMs(dto.dateAddedAtMs ?? dto.modifiedAtMs),
      modifiedAt: _dateTimeFromMs(dto.modifiedAtMs ?? dto.dateAddedAtMs),
      isHdr: dto.isHdr ||
          _containsAny(dto.displayName, const ['hdr', 'dolby vision']),
      is360Video: _containsAny(
        '${dto.displayName} ${dto.mimeType ?? ''} ${dto.metadataText ?? ''}',
        const ['360', 'vr', 'spherical', 'equirectangular'],
      ),
      isSlowMotion: (dto.frameRate ?? 0) >= 90 ||
          _containsAny(dto.displayName, const ['slow', 'slo-mo']),
      isHyperlapse: _containsAny(
        dto.displayName,
        const ['hyperlapse', 'time-lapse', 'timelapse', 'タイムラプス'],
      ),
      isDrm: dto.isDrm || _containsAny(dto.mimeType ?? '', const ['drm']),
      isPlayable: dto.isPlayable,
    );
  }

  Video _fromEntry(VideoIndexEntry entry) {
    return Video(
      id: entry.id,
      mediaStoreId: entry.mediaStoreId,
      uri: Uri.parse(entry.uri),
      displayName: entry.displayName,
      folderId: entry.folderId,
      folderName: entry.folderName,
      relativePath: entry.relativePath,
      mimeType: entry.mimeType,
      duration: _durationFromMs(entry.durationMs),
      sizeBytes: entry.sizeBytes,
      width: entry.width,
      height: entry.height,
      rotationDegrees: entry.rotationDegrees,
      bitrate: entry.bitrate,
      frameRate: entry.frameRate,
      videoCodec: entry.videoCodec,
      audioCodec: entry.audioCodec,
      audioChannelCount: entry.audioChannelCount,
      subtitleUri:
          entry.subtitleUri == null ? null : Uri.tryParse(entry.subtitleUri!),
      createdAt: _dateTimeFromMs(entry.createdAtMs),
      modifiedAt: _dateTimeFromMs(entry.modifiedAtMs),
      isHdr: entry.isHdr,
      is360Video: entry.is360Video,
      isSlowMotion: entry.isSlowMotion,
      isHyperlapse: entry.isHyperlapse,
      isDrm: entry.isDrm,
      isPlayable: entry.isPlayable,
      isFavorite: entry.isFavorite,
      isPrivate: entry.isPrivate,
      lastPlayedPosition: _durationFromMs(entry.lastPlayedPositionMs),
      lastPlayedAt: _dateTimeFromMs(entry.lastPlayedAtMs),
    );
  }

  VideoIndexEntriesCompanion _toEntry(Video video) {
    return VideoIndexEntriesCompanion.insert(
      id: video.id,
      mediaStoreId: video.mediaStoreId,
      uri: video.uri.toString(),
      displayName: video.displayName,
      folderId: video.folderId,
      folderName: video.folderName,
      relativePath: Value(video.relativePath),
      mimeType: Value(video.mimeType),
      durationMs: Value(video.duration?.inMilliseconds),
      sizeBytes: Value(video.sizeBytes),
      width: Value(video.width),
      height: Value(video.height),
      rotationDegrees: Value(video.rotationDegrees),
      bitrate: Value(video.bitrate),
      frameRate: Value(video.frameRate),
      videoCodec: Value(video.videoCodec),
      audioCodec: Value(video.audioCodec),
      audioChannelCount: Value(video.audioChannelCount),
      subtitleUri: Value(video.subtitleUri?.toString()),
      createdAtMs: Value(video.createdAt?.millisecondsSinceEpoch),
      modifiedAtMs: Value(video.modifiedAt?.millisecondsSinceEpoch),
      isHdr: Value(video.isHdr),
      is360Video: Value(video.is360Video),
      isSlowMotion: Value(video.isSlowMotion),
      isHyperlapse: Value(video.isHyperlapse),
      isDrm: Value(video.isDrm),
      isPlayable: Value(video.isPlayable),
      isFavorite: Value(video.isFavorite),
      isPrivate: Value(video.isPrivate),
      lastPlayedPositionMs: Value(video.lastPlayedPosition?.inMilliseconds),
      lastPlayedAtMs: Value(video.lastPlayedAt?.millisecondsSinceEpoch),
    );
  }

  Duration? _durationFromMs(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) {
      return null;
    }

    return Duration(milliseconds: milliseconds);
  }

  DateTime? _dateTimeFromMs(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  List<Video> _applyQuery(VideoQuery query) {
    final normalizedSearch = _normalizeSearchText(query.searchText);
    final filtered = _videos.where((video) {
      final matchesFolder =
          query.folderId == null || video.folderId == query.folderId;
      final matchesSearch = normalizedSearch.isEmpty ||
          _matchesSearchTarget(video, query.searchTarget, normalizedSearch);
      final matchesFilter = _matchesFilter(video, query.filter);
      final matchesPrivacy =
          query.filter == VideoFilter.privateVideos || !video.isPrivate;

      return matchesFolder && matchesSearch && matchesFilter && matchesPrivacy;
    }).toList();

    filtered.sort((a, b) {
      final result = switch (query.sortKey) {
        VideoSortKey.title => a.displayName.compareTo(b.displayName),
        VideoSortKey.createdAt => _compareDate(a.createdAt, b.createdAt),
        VideoSortKey.modifiedAt => _compareDate(a.modifiedAt, b.modifiedAt),
        VideoSortKey.sizeBytes =>
          (a.sizeBytes ?? 0).compareTo(b.sizeBytes ?? 0),
        VideoSortKey.duration => (a.duration?.inMilliseconds ?? 0)
            .compareTo(b.duration?.inMilliseconds ?? 0),
      };

      return query.sortOrder == SortOrder.ascending ? result : -result;
    });

    return List<Video>.unmodifiable(filtered);
  }

  int _compareDate(DateTime? a, DateTime? b) {
    return (a?.millisecondsSinceEpoch ?? 0)
        .compareTo(b?.millisecondsSinceEpoch ?? 0);
  }

  bool _matchesFilter(Video video, VideoFilter filter) {
    return switch (filter) {
      VideoFilter.all => true,
      VideoFilter.hdr => video.isHdr,
      VideoFilter.video360 => video.is360Video,
      VideoFilter.slowMotion => video.isSlowMotion,
      VideoFilter.hyperlapse => video.isHyperlapse,
      VideoFilter.drm => video.isDrm,
      VideoFilter.largeSize => (video.sizeBytes ?? 0) >= 1024 * 1024 * 500,
      VideoFilter.recentlyAdded => video.createdAt != null &&
          DateTime.now().difference(video.createdAt!).inDays <= 7,
      VideoFilter.recentlyPlayed => video.lastPlayedAt != null,
      VideoFilter.favorite => video.isFavorite,
      VideoFilter.privateVideos => video.isPrivate,
      VideoFilter.unplayable => !video.isPlayable,
    };
  }

  bool _matchesSearchTarget(
    Video video,
    VideoSearchTarget target,
    String normalizedSearch,
  ) {
    final title = _normalizeSearchText(video.displayName);
    final folder = _normalizeSearchText(video.folderName);

    return switch (target) {
      VideoSearchTarget.all =>
        title.contains(normalizedSearch) || folder.contains(normalizedSearch),
      VideoSearchTarget.title => title.contains(normalizedSearch),
      VideoSearchTarget.folder => folder.contains(normalizedSearch),
    };
  }

  String _normalizeSearchText(String text) {
    final buffer = StringBuffer();
    for (final codeUnit in text.trim().toLowerCase().codeUnits) {
      if (codeUnit == 0x3000) {
        buffer.writeCharCode(0x20);
      } else if (codeUnit >= 0xff01 && codeUnit <= 0xff5e) {
        buffer.writeCharCode(codeUnit - 0xfee0);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }

  bool _containsAny(String text, List<String> needles) {
    final normalized = text.toLowerCase();
    return needles.any(normalized.contains);
  }

  String _privateRestorePath(String? relativePath) {
    final normalized = _normalizeRelativePath(relativePath);
    if (normalized == null || normalized == _privateRelativePath) {
      return _defaultRestorePath;
    }

    return normalized;
  }

  String? _normalizeRelativePath(String? relativePath) {
    final trimmed = relativePath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return '${trimmed.replaceAll(RegExp(r'^/+|/+$'), '')}/';
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  void _replaceVideo(String videoId, Video Function(Video video) update) {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) {
      return;
    }

    _videos = [
      ..._videos.take(index),
      update(_videos[index]),
      ..._videos.skip(index + 1),
    ];
    unawaited(_database.updateVideoIndexEntry(_toEntry(_videos[index])));
    _emit();
  }

  static const _privateRelativePath = 'Movies/VideoLibraryPrivate/';
  static const _defaultRestorePath = 'Movies/';
}
