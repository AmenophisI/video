import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../data/video_folder_repository.dart';
import '../domain/folder.dart';
import '../domain/folder_repository.dart';
import 'observe_folder_videos_use_case.dart';
import 'observe_folders_use_case.dart';

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return VideoFolderRepository(ref.watch(videoRepositoryProvider));
});

final observeFoldersUseCaseProvider = Provider<ObserveFoldersUseCase>((ref) {
  return ObserveFoldersUseCase(ref.watch(folderRepositoryProvider));
});

final observeFolderVideosUseCaseProvider =
    Provider<ObserveFolderVideosUseCase>((ref) {
  return ObserveFolderVideosUseCase(ref.watch(videoRepositoryProvider));
});

final folderListProvider = StreamProvider<List<Folder>>((ref) {
  return ref.watch(observeFoldersUseCaseProvider).call();
});

final folderVideosProvider =
    StreamProvider.family<List<Video>, String>((ref, folderId) {
  return ref.watch(observeFolderVideosUseCaseProvider).call(folderId);
});
