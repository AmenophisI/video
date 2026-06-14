import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../../video/domain/video.dart';
import '../../video/application/video_providers.dart';
import 'open_video_use_case.dart';
import 'save_playback_position_use_case.dart';

final openVideoUseCaseProvider = Provider<OpenVideoUseCase>((ref) {
  return OpenVideoUseCase(
    videoRepository: ref.watch(videoRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final savePlaybackPositionUseCaseProvider =
    Provider<SavePlaybackPositionUseCase>((ref) {
  return SavePlaybackPositionUseCase(
    videoRepository: ref.watch(videoRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final playbackVideoProvider = FutureProvider.family<Video?, String>((ref, id) {
  return ref.watch(openVideoUseCaseProvider).call(id);
});
