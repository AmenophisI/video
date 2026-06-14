import 'package:shared_preferences/shared_preferences.dart';

import '../domain/video_query.dart';

abstract interface class VideoQueryPreferences {
  Future<VideoQuery> load();

  Future<void> save(VideoQuery query);
}

class VideoQueryPreferencesStore implements VideoQueryPreferences {
  VideoQueryPreferencesStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<VideoQuery> load() async {
    final sortKeyName = await _preferences.getString(_sortKeyKey);
    final sortOrderName = await _preferences.getString(_sortOrderKey);
    final filterName = await _preferences.getString(_filterKey);
    final searchTargetName = await _preferences.getString(_searchTargetKey);

    final filter = VideoFilter.values
            .where((value) => value.name == filterName)
            .firstOrNull ??
        VideoFilter.all;

    return VideoQuery(
      sortKey: VideoSortKey.values
              .where((value) => value.name == sortKeyName)
              .firstOrNull ??
          VideoSortKey.modifiedAt,
      sortOrder: SortOrder.values
              .where((value) => value.name == sortOrderName)
              .firstOrNull ??
          SortOrder.descending,
      searchTarget: VideoSearchTarget.values
              .where((value) => value.name == searchTargetName)
              .firstOrNull ??
          VideoSearchTarget.all,
      filter: filter == VideoFilter.privateVideos ? VideoFilter.all : filter,
    );
  }

  @override
  Future<void> save(VideoQuery query) async {
    await Future.wait([
      _preferences.setString(_sortKeyKey, query.sortKey.name),
      _preferences.setString(_sortOrderKey, query.sortOrder.name),
      _preferences.setString(_filterKey, query.filter.name),
      _preferences.setString(_searchTargetKey, query.searchTarget.name),
    ]);
  }

  static const _sortKeyKey = 'videoQuery.sortKey';
  static const _sortOrderKey = 'videoQuery.sortOrder';
  static const _filterKey = 'videoQuery.filter';
  static const _searchTargetKey = 'videoQuery.searchTarget';
}
