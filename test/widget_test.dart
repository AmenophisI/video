import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:video_player/src/app/app.dart';
import 'package:video_player/src/modules/media_access/domain/media_permission.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/data/video_query_preferences_store.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';
import 'package:video_player/src/modules/video/presentation/widgets/playback_progress_bar.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows the video library scaffold', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
          mediaPermissionProvider.overrideWith((ref) async {
            return MediaPermission.granted;
          }),
          videoQueryPreferencesStoreProvider.overrideWithValue(
            _FakeVideoQueryPreferencesStore(),
          ),
        ],
        child: const VideoLibraryApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('動画'), findsOneWidget);
    expect(find.text('フォルダ'), findsOneWidget);
    expect(find.text('リスト'), findsNothing);
    expect(find.text('設定'), findsNothing);
    expect(find.text('家族旅行.mp4'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byType(PlaybackProgressBar), findsWidgets);
  });

  testWidgets('shows limited permission guidance when access is partial',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
          mediaPermissionProvider.overrideWith((ref) async {
            return MediaPermission.limited;
          }),
          videoQueryPreferencesStoreProvider.overrideWithValue(
            _FakeVideoQueryPreferencesStore(),
          ),
        ],
        child: const VideoLibraryApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('選択した動画のみ表示しています'), findsOneWidget);
    expect(find.text('追加選択'), findsOneWidget);
  });

  testWidgets('clears selection when the library query changes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
          mediaPermissionProvider.overrideWith((ref) async {
            return MediaPermission.granted;
          }),
          videoQueryPreferencesStoreProvider.overrideWithValue(
            _FakeVideoQueryPreferencesStore(),
          ),
        ],
        child: const VideoLibraryApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.text('家族旅行.mp4'));
    await tester.pumpAndSettle();

    expect(find.text('1件選択'), findsOneWidget);

    await tester.tap(find.text('その他'));
    await tester.pumpAndSettle();
    expect(find.text('セキュリティフォルダに移動'), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    await tester.tap(find.text('共有'));
    await tester.pump();
    expect(find.text('1件選択'), findsOneWidget);

    await tester.tap(find.byTooltip('選択解除'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('検索'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '料理');
    await tester.pump();

    expect(find.text('動画'), findsOneWidget);
    expect(find.text('1件選択'), findsNothing);
  });
}

class _FakeVideoQueryPreferencesStore implements VideoQueryPreferences {
  VideoQuery _query = const VideoQuery();

  @override
  Future<VideoQuery> load() async => _query;

  @override
  Future<void> save(VideoQuery query) async {
    _query = query;
  }
}
