import '../../settings/domain/settings_repository.dart';
import '../../video/domain/video_repository.dart';

class SavePlaybackPositionUseCase {
  const SavePlaybackPositionUseCase({
    required VideoRepository videoRepository,
    required SettingsRepository settingsRepository,
  })  : _videoRepository = videoRepository,
        _settingsRepository = settingsRepository;

  final VideoRepository _videoRepository;
  final SettingsRepository _settingsRepository;

  Future<void> call({
    required String videoId,
    required Duration position,
  }) async {
    final settings = await _settingsRepository.watchSettings().first;
    if (!settings.rememberPlaybackPosition) {
      return;
    }

    await _videoRepository.updatePlaybackPosition(
      videoId: videoId,
      position: position,
    );
  }
}
