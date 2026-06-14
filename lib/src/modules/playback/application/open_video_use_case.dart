import '../../settings/domain/settings_repository.dart';
import '../../video/domain/video.dart';
import '../../video/domain/video_repository.dart';

class OpenVideoUseCase {
  const OpenVideoUseCase({
    required VideoRepository videoRepository,
    required SettingsRepository settingsRepository,
  })  : _videoRepository = videoRepository,
        _settingsRepository = settingsRepository;

  final VideoRepository _videoRepository;
  final SettingsRepository _settingsRepository;

  Future<Video?> call(String videoId) async {
    final video = await _videoRepository.getVideo(videoId);
    final settings = await _settingsRepository.watchSettings().first;

    if (video == null) {
      return video;
    }

    if (!settings.rememberPlaybackPosition) {
      return video.copyWith(clearPlaybackPosition: true);
    }

    return video;
  }
}
