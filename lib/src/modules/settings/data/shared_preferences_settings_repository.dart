import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  AppSettings? _cachedSettings;

  @override
  Stream<AppSettings> watchSettings() async* {
    _cachedSettings ??= await _loadSettings();
    yield _cachedSettings!;
    yield* _controller.stream;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _cachedSettings = settings;
    await Future.wait([
      _preferences.setString(_viewModeKey, settings.viewMode.name),
      _preferences.setBool(
        _rememberPlaybackPositionKey,
        settings.rememberPlaybackPosition,
      ),
      _preferences.setBool(
        _showPlaybackProgressKey,
        settings.showPlaybackProgress,
      ),
      _preferences.setBool(
        _showVideoTagsKey,
        settings.showVideoTags,
      ),
      _preferences.setBool(
        _enableInstantPlayerKey,
        settings.enableInstantPlayer,
      ),
      _preferences.setInt(
        _thumbnailCacheLimitMbKey,
        settings.thumbnailCacheLimitMb,
      ),
      _preferences.setString(
        _privateLockMethodKey,
        settings.privateLockMethod.name,
      ),
      if (settings.privatePin == null)
        _preferences.remove(_privatePinKey)
      else
        _preferences.setString(_privatePinKey, settings.privatePin!),
    ]);

    if (!_controller.isClosed) {
      _controller.add(settings);
    }
  }

  void dispose() {
    _controller.close();
  }

  Future<AppSettings> _loadSettings() async {
    final viewModeName = await _preferences.getString(_viewModeKey);
    final viewMode = LibraryViewMode.values
        .where((mode) => mode.name == viewModeName)
        .firstOrNull;

    return AppSettings(
      viewMode: viewMode ?? LibraryViewMode.grid,
      rememberPlaybackPosition:
          await _preferences.getBool(_rememberPlaybackPositionKey) ?? true,
      showPlaybackProgress:
          await _preferences.getBool(_showPlaybackProgressKey) ?? true,
      showVideoTags: await _preferences.getBool(_showVideoTagsKey) ?? true,
      enableInstantPlayer:
          await _preferences.getBool(_enableInstantPlayerKey) ?? true,
      thumbnailCacheLimitMb:
          await _preferences.getInt(_thumbnailCacheLimitMbKey) ?? 512,
      privatePin: await _preferences.getString(_privatePinKey),
      privateLockMethod: _privateLockMethodFromName(
        await _preferences.getString(_privateLockMethodKey),
      ),
    );
  }

  PrivateLockMethod _privateLockMethodFromName(String? name) {
    return PrivateLockMethod.values
            .where((method) => method.name == name)
            .firstOrNull ??
        PrivateLockMethod.pinOrDeviceCredential;
  }

  static const _viewModeKey = 'settings.viewMode';
  static const _rememberPlaybackPositionKey =
      'settings.rememberPlaybackPosition';
  static const _showPlaybackProgressKey = 'settings.showPlaybackProgress';
  static const _showVideoTagsKey = 'settings.showVideoTags';
  static const _enableInstantPlayerKey = 'settings.enableInstantPlayer';
  static const _thumbnailCacheLimitMbKey = 'settings.thumbnailCacheLimitMb';
  static const _privatePinKey = 'settings.privatePin';
  static const _privateLockMethodKey = 'settings.privateLockMethod';
}
