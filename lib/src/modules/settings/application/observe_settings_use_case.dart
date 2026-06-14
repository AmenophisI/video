import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class ObserveSettingsUseCase {
  const ObserveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  Stream<AppSettings> call() {
    return _repository.watchSettings();
  }
}
