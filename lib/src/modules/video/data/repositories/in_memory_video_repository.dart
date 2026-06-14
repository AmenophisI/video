import 'dart:async';

import '../../domain/video.dart';
import '../../domain/video_query.dart';
import '../../domain/video_repository.dart';

class InMemoryVideoRepository implements VideoRepository {
  InMemoryVideoRepository({required List<Video> seedVideos})
      : _videos = List<Video>.of(seedVideos);

  factory InMemoryVideoRepository.seeded() {
    final now = DateTime.now();

    return InMemoryVideoRepository(
      seedVideos: [
        Video(
          id: 'video-001',
          mediaStoreId: 1,
          uri: Uri.parse('content://media/external/video/media/1'),
          displayName: '家族旅行.mp4',
          folderId: 'camera',
          folderName: 'Camera',
          duration: const Duration(minutes: 4, seconds: 32),
          sizeBytes: 164000000,
          createdAt: now.subtract(const Duration(days: 4)),
          modifiedAt: now.subtract(const Duration(days: 4)),
          lastPlayedPosition: const Duration(minutes: 1, seconds: 12),
          lastPlayedAt: now.subtract(const Duration(hours: 6)),
        ),
        Video(
          id: 'video-002',
          mediaStoreId: 2,
          uri: Uri.parse('content://media/external/video/media/2'),
          displayName: '料理メモ.webm',
          folderId: 'downloads',
          folderName: 'Download',
          duration: const Duration(minutes: 1, seconds: 48),
          sizeBytes: 52000000,
          createdAt: now.subtract(const Duration(days: 1)),
          modifiedAt: now.subtract(const Duration(days: 1)),
        ),
        Video(
          id: 'video-003',
          mediaStoreId: 3,
          uri: Uri.parse('content://media/external/video/media/3'),
          displayName: 'スローモーション練習.mov',
          folderId: 'camera',
          folderName: 'Camera',
          duration: const Duration(minutes: 8, seconds: 4),
          sizeBytes: 381000000,
          createdAt: now.subtract(const Duration(days: 10)),
          modifiedAt: now.subtract(const Duration(days: 8)),
          isSlowMotion: true,
          lastPlayedPosition: const Duration(minutes: 6, seconds: 18),
          lastPlayedAt: now.subtract(const Duration(days: 2)),
        ),
        Video(
          id: 'video-004',
          mediaStoreId: 4,
          uri: Uri.parse('content://media/external/video/media/4'),
          displayName: 'Hyperlapse_駅前.mp4',
          folderId: 'camera',
          folderName: 'Camera',
          duration: const Duration(seconds: 42),
          sizeBytes: 86000000,
          createdAt: now.subtract(const Duration(days: 2)),
          modifiedAt: now.subtract(const Duration(days: 2)),
          isHyperlapse: true,
        ),
      ],
    );
  }

  final List<Video> _videos;
  final List<String> _searchHistory = [];
  final StreamController<List<Video>> _controller =
      StreamController<List<Video>>.broadcast();

  @override
  Stream<List<Video>> watchVideos(VideoQuery query) async* {
    yield _applyQuery(query);
    yield* _controller.stream.map((_) => _applyQuery(query));
  }

  @override
  Future<Video?> getVideo(String id) async {
    for (final video in _videos) {
      if (video.id == id) {
        return video;
      }
    }

    return null;
  }

  @override
  Future<void> refreshIndex() async {
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

    _videos[index] = _videos[index].copyWith(
      lastPlayedPosition: position,
      lastPlayedAt: DateTime.now(),
    );
    _emit();
  }

  @override
  Future<void> shareVideo(String videoId) async {
    _requireVideo(videoId);
  }

  @override
  Future<void> shareVideos(List<String> videoIds) async {
    for (final videoId in videoIds) {
      _requireVideo(videoId);
    }
  }

  @override
  Future<void> openVideoInEditor(String videoId) async {
    _requireVideo(videoId);
  }

  @override
  Future<void> openVideoInExternalPlayer(String videoId) async {
    _requireVideo(videoId);
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    _videos.removeWhere((video) => video.id == videoId);
    _emit();
  }

  @override
  Future<void> deleteVideos(List<String> videoIds) async {
    final targetIds = videoIds.toSet();
    _videos.removeWhere((video) => targetIds.contains(video.id));
    _emit();
  }

  @override
  Future<void> renameVideo({
    required String videoId,
    required String displayName,
  }) async {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) {
      return;
    }

    _videos[index] = _videos[index].copyWith(displayName: displayName);
    _emit();
  }

  @override
  Future<void> moveVideo({
    required String videoId,
    required String relativePath,
  }) async {
    _replaceVideo(
        videoId, (video) => video.copyWith(relativePath: relativePath));
  }

  @override
  Future<void> copyVideo({
    required String videoId,
    required String relativePath,
    String? displayName,
  }) async {
    final source = _requireVideo(videoId);
    _videos.add(
      Video(
        id: '${source.id}-copy-${_videos.length + 1}',
        mediaStoreId: source.mediaStoreId,
        uri: source.uri,
        displayName: displayName ?? source.displayName,
        folderId: source.folderId,
        folderName: source.folderName,
        relativePath: relativePath,
        mimeType: source.mimeType,
        duration: source.duration,
        sizeBytes: source.sizeBytes,
        width: source.width,
        height: source.height,
        rotationDegrees: source.rotationDegrees,
        bitrate: source.bitrate,
        frameRate: source.frameRate,
        createdAt: source.createdAt,
        modifiedAt: DateTime.now(),
        thumbnailUri: source.thumbnailUri,
        subtitleUri: source.subtitleUri,
        isHdr: source.isHdr,
        is360Video: source.is360Video,
        isSlowMotion: source.isSlowMotion,
        isHyperlapse: source.isHyperlapse,
        isDrm: source.isDrm,
        isPlayable: source.isPlayable,
      ),
    );
    _emit();
  }

  void dispose() {
    _controller.close();
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

  @override
  Future<void> setFavorite({
    required String videoId,
    required bool isFavorite,
  }) async {
    _replaceVideo(videoId, (video) => video.copyWith(isFavorite: isFavorite));
  }

  @override
  Future<void> setPrivate({
    required String videoId,
    required bool isPrivate,
  }) async {
    _replaceVideo(
      videoId,
      (video) => video.copyWith(
        isPrivate: isPrivate,
        relativePath: isPrivate
            ? 'Movies/VideoLibraryPrivate/'
            : video.relativePath == 'Movies/VideoLibraryPrivate/'
                ? 'Movies/'
                : video.relativePath,
      ),
    );
  }

  @override
  Future<void> addSearchHistory(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return;
    }

    _searchHistory
      ..remove(normalized)
      ..insert(0, normalized);
    if (_searchHistory.length > 10) {
      _searchHistory.removeRange(10, _searchHistory.length);
    }
  }

  @override
  Future<List<String>> getSearchHistory() async {
    return List.unmodifiable(_searchHistory);
  }

  @override
  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
  }

  void _replaceVideo(String videoId, Video Function(Video video) update) {
    final index = _videos.indexWhere((video) => video.id == videoId);
    if (index == -1) {
      return;
    }

    _videos[index] = update(_videos[index]);
    _emit();
  }

  Video _requireVideo(String videoId) {
    for (final video in _videos) {
      if (video.id == videoId) {
        return video;
      }
    }

    throw StateError('Video not found: $videoId');
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Video>.unmodifiable(_videos));
    }
  }
}
