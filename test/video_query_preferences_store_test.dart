import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:video_player/src/modules/video/data/video_query_preferences_store.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('loads default query when preferences are empty', () async {
    final store = VideoQueryPreferencesStore();

    final query = await store.load();

    expect(query.sortKey, VideoSortKey.modifiedAt);
    expect(query.sortOrder, SortOrder.descending);
    expect(query.searchTarget, VideoSearchTarget.all);
    expect(query.filter, VideoFilter.all);
    expect(query.searchText, isEmpty);
    expect(query.folderId, isNull);
  });

  test('persists library sort, filter, and search target preferences',
      () async {
    final store = VideoQueryPreferencesStore();

    await store.save(
      const VideoQuery(
        sortKey: VideoSortKey.duration,
        sortOrder: SortOrder.ascending,
        searchTarget: VideoSearchTarget.folder,
        filter: VideoFilter.favorite,
      ),
    );

    final reloaded = await VideoQueryPreferencesStore().load();

    expect(reloaded.sortKey, VideoSortKey.duration);
    expect(reloaded.sortOrder, SortOrder.ascending);
    expect(reloaded.searchTarget, VideoSearchTarget.folder);
    expect(reloaded.filter, VideoFilter.favorite);
  });

  test('does not restore private video filter on normal app launch', () async {
    final store = VideoQueryPreferencesStore();

    await store.save(const VideoQuery(filter: VideoFilter.privateVideos));

    final reloaded = await VideoQueryPreferencesStore().load();

    expect(reloaded.filter, VideoFilter.all);
  });
}
