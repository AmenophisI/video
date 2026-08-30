import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:video_player/src/modules/settings/data/shared_preferences_settings_repository.dart';
import 'package:video_player/src/modules/settings/domain/app_settings.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('loads default settings when preferences are empty', () async {
    final repository = SharedPreferencesSettingsRepository();

    final settings = await repository.watchSettings().first;

    expect(settings.viewMode, LibraryViewMode.list);
    expect(settings.lastTabIndex, 0);
    expect(settings.rememberPlaybackPosition, isTrue);
    expect(settings.showPlaybackProgress, isTrue);
    expect(settings.showVideoTags, isTrue);
    expect(settings.enableInstantPlayer, isFalse);
    expect(settings.videoBrightness, 0.5);
    expect(settings.thumbnailCacheLimitMb, 512);
    expect(settings.privatePin, isNull);
    expect(
      settings.privateLockMethod,
      PrivateLockMethod.pinOrDeviceCredential,
    );
  });

  test('persists updated settings and emits them to watchers', () async {
    final repository = SharedPreferencesSettingsRepository();
    final updates = <AppSettings>[];
    final initialSettings = Completer<void>();
    final subscription = repository.watchSettings().listen((settings) {
      updates.add(settings);
      if (!initialSettings.isCompleted) {
        initialSettings.complete();
      }
    });
    await initialSettings.future;

    await repository.updateSettings(
      const AppSettings(
        viewMode: LibraryViewMode.list,
        lastTabIndex: 1,
        rememberPlaybackPosition: false,
        showPlaybackProgress: false,
        showVideoTags: false,
        enableInstantPlayer: false,
        videoBrightness: 0.8,
        thumbnailCacheLimitMb: 128,
        privatePin: '1234',
        privateLockMethod: PrivateLockMethod.pin,
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(updates, hasLength(2));
    expect(updates.last.viewMode, LibraryViewMode.list);
    expect(updates.last.lastTabIndex, 1);
    expect(updates.last.rememberPlaybackPosition, isFalse);
    expect(updates.last.showPlaybackProgress, isFalse);
    expect(updates.last.showVideoTags, isFalse);
    expect(updates.last.enableInstantPlayer, isFalse);
    expect(updates.last.videoBrightness, 0.8);
    expect(updates.last.thumbnailCacheLimitMb, 128);
    expect(updates.last.privatePin, '1234');
    expect(updates.last.privateLockMethod, PrivateLockMethod.pin);

    final reloaded =
        await SharedPreferencesSettingsRepository().watchSettings().first;
    expect(reloaded.viewMode, LibraryViewMode.list);
    expect(reloaded.lastTabIndex, 1);
    expect(reloaded.rememberPlaybackPosition, isFalse);
    expect(reloaded.showPlaybackProgress, isFalse);
    expect(reloaded.showVideoTags, isFalse);
    expect(reloaded.enableInstantPlayer, isFalse);
    expect(reloaded.videoBrightness, 0.8);
    expect(reloaded.thumbnailCacheLimitMb, 128);
    expect(reloaded.privatePin, '1234');
    expect(reloaded.privateLockMethod, PrivateLockMethod.pin);
  });

  test('removes private PIN when settings clear it', () async {
    final repository = SharedPreferencesSettingsRepository();

    await repository.updateSettings(const AppSettings(privatePin: '1234'));
    await repository.updateSettings(
      const AppSettings(privateLockMethod: PrivateLockMethod.deviceCredential),
    );

    final reloaded =
        await SharedPreferencesSettingsRepository().watchSettings().first;
    expect(reloaded.privatePin, isNull);
    expect(reloaded.privateLockMethod, PrivateLockMethod.deviceCredential);
  });
}
