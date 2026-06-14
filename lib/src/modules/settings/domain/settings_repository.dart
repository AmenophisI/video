import 'app_settings.dart';

abstract interface class SettingsRepository {
  Stream<AppSettings> watchSettings();

  Future<void> updateSettings(AppSettings settings);
}
