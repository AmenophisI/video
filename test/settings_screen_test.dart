import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/media_access/domain/media_permission.dart';
import 'package:video_player/src/modules/settings/application/settings_providers.dart';
import 'package:video_player/src/modules/settings/data/in_memory_settings_repository.dart';
import 'package:video_player/src/modules/settings/presentation/settings_screen.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/data/video_query_preferences_store.dart';
import 'package:video_player/src/modules/video/domain/video_query.dart';

void main() {
  testWidgets('settings screen scrolls on small screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final settingsRepository = InMemorySettingsRepository();
    addTearDown(settingsRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
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
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child!,
            );
          },
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ListView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('プライベートPIN'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('プライベートPIN'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('プライベートロック方式'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('プライベートロック方式'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<VideoSortKey>),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(DropdownButtonFormField<VideoSortKey>), findsOneWidget);
    expect(tester.takeException(), isNull);
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
