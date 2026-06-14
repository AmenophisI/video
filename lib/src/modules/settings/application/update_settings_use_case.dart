import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class UpdateSettingsUseCase {
  const UpdateSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> call(AppSettings settings) {
    return _repository.updateSettings(settings);
  }
}
