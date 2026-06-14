import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media_access/data/media_store/media_store_adapter.dart';
import '../../media_access/data/permissions/media_permission_adapter.dart';
import '../../media_access/domain/media_permission.dart';
import '../data/repositories/media_store_video_repository.dart';
import '../data/video_query_preferences_store.dart';
import '../domain/video.dart';
import '../domain/video_query.dart';
import '../domain/video_repository.dart';
import 'observe_video_library_use_case.dart';
import 'scan_videos_use_case.dart';
import 'search_videos_use_case.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final repository = MediaStoreVideoRepository(
    mediaStoreAdapter: ref.watch(mediaStoreAdapterProvider),
    permissionAdapter: ref.watch(mediaPermissionAdapterProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final mediaStoreAdapterProvider = Provider<MediaStoreAdapter>((ref) {
  return MediaStoreAdapter();
});

final mediaPermissionAdapterProvider = Provider<MediaPermissionAdapter>((ref) {
  return const MediaPermissionAdapter();
});

final mediaPermissionProvider = FutureProvider<MediaPermission>((ref) {
  return ref.watch(mediaPermissionAdapterProvider).checkPermission();
});

final videoQueryProvider = StateProvider<VideoQuery>((ref) {
  return const VideoQuery();
});

final videoQueryPreferencesStoreProvider =
    Provider<VideoQueryPreferences>((ref) {
  return VideoQueryPreferencesStore();
});

final observeVideoLibraryUseCaseProvider =
    Provider<ObserveVideoLibraryUseCase>((ref) {
  return ObserveVideoLibraryUseCase(ref.watch(videoRepositoryProvider));
});

final scanVideosUseCaseProvider = Provider<ScanVideosUseCase>((ref) {
  return ScanVideosUseCase(ref.watch(videoRepositoryProvider));
});

final searchVideosUseCaseProvider = Provider<SearchVideosUseCase>((ref) {
  return const SearchVideosUseCase();
});

final videoLibraryProvider = StreamProvider<List<Video>>((ref) {
  final query = ref.watch(videoQueryProvider);
  final useCase = ref.watch(observeVideoLibraryUseCaseProvider);
  return useCase(query);
});

final videoByIdProvider = FutureProvider.family<Video?, String>((ref, id) {
  return ref.watch(videoRepositoryProvider).getVideo(id);
});

final searchHistoryProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(videoRepositoryProvider).getSearchHistory();
});
