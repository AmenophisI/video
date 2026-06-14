import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VideoMetadata {
  const VideoMetadata({
    required this.favoriteVideoIds,
    required this.privateVideoIds,
    required this.privateOriginalPaths,
  });

  final Set<String> favoriteVideoIds;
  final Set<String> privateVideoIds;
  final Map<String, String> privateOriginalPaths;
}

class VideoMetadataStore {
  VideoMetadataStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<VideoMetadata> loadMetadata() async {
    final favoriteIds = await _preferences.getStringList(_favoriteVideoIdsKey);
    final privateIds = await _preferences.getStringList(_privateVideoIdsKey);
    final privateOriginalPaths = await _loadStringMap(_privateOriginalPathsKey);

    return VideoMetadata(
      favoriteVideoIds: {...?favoriteIds},
      privateVideoIds: {...?privateIds},
      privateOriginalPaths: privateOriginalPaths,
    );
  }

  Future<void> setFavorite({
    required String videoId,
    required bool isFavorite,
  }) async {
    final metadata = await loadMetadata();
    final ids = {...metadata.favoriteVideoIds};
    if (isFavorite) {
      ids.add(videoId);
    } else {
      ids.remove(videoId);
    }

    await _preferences.setStringList(_favoriteVideoIdsKey, ids.toList());
  }

  Future<void> setPrivate({
    required String videoId,
    required bool isPrivate,
  }) async {
    final metadata = await loadMetadata();
    final ids = {...metadata.privateVideoIds};
    if (isPrivate) {
      ids.add(videoId);
    } else {
      ids.remove(videoId);
    }

    await _preferences.setStringList(_privateVideoIdsKey, ids.toList());
  }

  Future<void> setPrivateOriginalPath({
    required String videoId,
    required String? relativePath,
  }) async {
    final paths = await _loadStringMap(_privateOriginalPathsKey);
    if (relativePath == null || relativePath.isEmpty) {
      paths.remove(videoId);
    } else {
      paths[videoId] = relativePath;
    }

    await _preferences.setString(_privateOriginalPathsKey, jsonEncode(paths));
  }

  Future<String?> getPrivateOriginalPath(String videoId) async {
    final paths = await _loadStringMap(_privateOriginalPathsKey);
    return paths[videoId];
  }

  Future<List<String>> loadSearchHistory() async {
    return await _preferences.getStringList(_searchHistoryKey) ?? const [];
  }

  Future<void> addSearchHistory(String keyword) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) {
      return;
    }

    final history = await loadSearchHistory();
    final next = [
      normalized,
      ...history.where((item) => item != normalized),
    ].take(10).toList(growable: false);

    await _preferences.setStringList(_searchHistoryKey, next);
  }

  Future<void> clearSearchHistory() async {
    await _preferences.remove(_searchHistoryKey);
  }

  Future<Map<String, String>> _loadStringMap(String key) async {
    final source = await _preferences.getString(key);
    if (source == null || source.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      return {};
    }

    return {
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }

  static const _favoriteVideoIdsKey = 'video.favoriteIds';
  static const _privateVideoIdsKey = 'video.privateIds';
  static const _privateOriginalPathsKey = 'video.privateOriginalPaths';
  static const _searchHistoryKey = 'video.searchHistory';
}
