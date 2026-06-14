import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(appSettingsProvider).maybeWhen(
          data: (settings) => settings,
          orElse: () => const AppSettings(),
        );
  }

  Future<void> update(AppSettings settings) {
    state = settings;
    return ref.read(updateSettingsUseCaseProvider).call(settings);
  }
}
