import 'dart:async';

import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings();
  final StreamController<AppSettings> _controller =
      StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> watchSettings() async* {
    yield _settings;
    yield* _controller.stream;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    if (!_controller.isClosed) {
      _controller.add(_settings);
    }
  }

  void dispose() {
    _controller.close();
  }
}
