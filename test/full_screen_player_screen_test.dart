import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/playback/presentation/full_screen_player_screen.dart';
import 'package:video_player/src/modules/settings/application/settings_providers.dart';
import 'package:video_player/src/modules/settings/domain/app_settings.dart';
import 'package:video_player/src/modules/settings/domain/settings_repository.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/domain/video.dart';

void main() {
  testWidgets('shows playback controls in fullscreen player', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: FullScreenPlayerScreen(videoId: 'video-001'),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Slider), findsNothing);
    await tester.tapAt(const Offset(180, 300));
    await tester.pump();

    expect(find.text('家族旅行.mp4'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byTooltip('一時停止'), findsOneWidget);
    expect(find.byTooltip('10秒戻る'), findsOneWidget);
    expect(find.byIcon(Icons.replay_10), findsOneWidget);

    await tester.tapAt(const Offset(180, 300));
    await tester.pump();

    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('shows subtitle control when subtitle is available',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository(
              seedVideos: [
                Video(
                  id: 'video-subtitle',
                  mediaStoreId: 10,
                  uri: Uri.parse('content://media/external/video/media/10'),
                  displayName: '字幕付き.mp4',
                  folderId: 'download',
                  folderName: 'Download',
                  subtitleUri: Uri.parse(
                    'content://media/external/file/10',
                  ),
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: FullScreenPlayerScreen(videoId: 'video-subtitle'),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(const Offset(180, 300));
    await tester.pump();

    expect(find.text('字幕付き.mp4'), findsOneWidget);
    expect(find.byTooltip('字幕OFF'), findsWidgets);
    expect(find.byIcon(Icons.closed_caption), findsWidgets);
  });

  testWidgets('fullscreen player scrolls on small screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository(
              seedVideos: [
                Video(
                  id: 'video-small-screen',
                  mediaStoreId: 11,
                  uri: Uri.parse('content://media/external/video/media/11'),
                  displayName: 'とても長い名前の字幕付き動画ファイル.mp4',
                  folderId: 'download',
                  folderName: 'Download',
                  duration: const Duration(hours: 1, minutes: 2, seconds: 3),
                  subtitleUri: Uri.parse(
                    'content://media/external/file/11',
                  ),
                ),
              ],
            ),
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
          home: const FullScreenPlayerScreen(videoId: 'video-small-screen'),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(const Offset(180, 260));
    await tester.pump();

    expect(find.byTooltip('字幕OFF'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fullscreen player uses stable landscape layout', (tester) async {
    tester.view.physicalSize = const Size(900, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: FullScreenPlayerScreen(videoId: 'video-001'),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(const Offset(450, 210));
    await tester.pump();

    expect(find.text('家族旅行.mp4'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.byTooltip('一時停止'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal drag previews relative seek offset', (tester) async {
    tester.view.physicalSize = const Size(820, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: FullScreenPlayerScreen(videoId: 'video-001'),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(const Offset(410, 180));
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();

    expect(find.textContaining('+00:'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('unplayable player panel scrolls on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository(
              seedVideos: [
                Video(
                  id: 'video-unplayable-small',
                  mediaStoreId: 12,
                  uri: Uri.parse('content://media/external/video/media/12'),
                  displayName: '再生できない長い名前の動画ファイル.mp4',
                  folderId: 'download',
                  folderName: 'Download',
                  isPlayable: false,
                ),
              ],
            ),
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
          home: const FullScreenPlayerScreen(
            videoId: 'video-unplayable-small',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('この動画はアプリ内で再生できません'), findsOneWidget);
    expect(find.text('外部プレイヤーで開く'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unplayable DRM video explains why playback is unavailable',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(
            const _TestSettingsRepository(),
          ),
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository(
              seedVideos: [
                Video(
                  id: 'video-drm-unplayable',
                  mediaStoreId: 13,
                  uri: Uri.parse('content://media/external/video/media/13'),
                  displayName: 'protected.mp4',
                  folderId: 'download',
                  folderName: 'Download',
                  isDrm: true,
                  isPlayable: false,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: FullScreenPlayerScreen(videoId: 'video-drm-unplayable'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('この動画はアプリ内で再生できません'), findsOneWidget);
    expect(find.textContaining('DRM保護'), findsOneWidget);
  });
}

class _TestSettingsRepository implements SettingsRepository {
  const _TestSettingsRepository();

  @override
  Stream<AppSettings> watchSettings() => Stream.value(const AppSettings());

  @override
  Future<void> updateSettings(AppSettings settings) async {}
}
