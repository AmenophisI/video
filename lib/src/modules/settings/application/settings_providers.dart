import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_settings_repository.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';
import 'observe_settings_use_case.dart';
import 'private_access_authenticator.dart';
import 'update_settings_use_case.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final repository = SharedPreferencesSettingsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final observeSettingsUseCaseProvider = Provider<ObserveSettingsUseCase>((ref) {
  return ObserveSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

final updateSettingsUseCaseProvider = Provider<UpdateSettingsUseCase>((ref) {
  return UpdateSettingsUseCase(ref.watch(settingsRepositoryProvider));
});

final privateAccessAuthenticatorProvider =
    Provider<PrivateAccessAuthenticator>((ref) {
  return PrivateAccessAuthenticator();
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(observeSettingsUseCaseProvider).call();
});
