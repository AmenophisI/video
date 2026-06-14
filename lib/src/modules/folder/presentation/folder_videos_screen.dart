import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../video/presentation/video_library_screen.dart';
import '../application/folder_providers.dart';
import '../domain/folder.dart';

class FolderVideosScreen extends ConsumerWidget {
  const FolderVideosScreen({
    required this.folder,
    super.key,
  });

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(folderVideosProvider(folder.id));
    final settings = ref.watch(appSettingsProvider).maybeWhen(
          data: (settings) => settings,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          IconButton(
            tooltip: (settings?.viewMode ?? LibraryViewMode.grid) ==
                    LibraryViewMode.grid
                ? 'リスト表示'
                : 'グリッド表示',
            onPressed: settings == null
                ? null
                : () {
                    final nextViewMode =
                        settings.viewMode == LibraryViewMode.grid
                            ? LibraryViewMode.list
                            : LibraryViewMode.grid;
                    ref.read(updateSettingsUseCaseProvider).call(
                          settings.copyWith(viewMode: nextViewMode),
                        );
                  },
            icon: Icon(
              (settings?.viewMode ?? LibraryViewMode.grid) ==
                      LibraryViewMode.grid
                  ? Icons.view_list
                  : Icons.grid_view,
            ),
          ),
        ],
      ),
      body: videosAsync.when(
        data: (videos) => VideoGrid(
          videos: videos,
          showPlaybackProgress: settings?.showPlaybackProgress ?? true,
          showTags: settings?.showVideoTags ?? true,
          enableInstantPlayer: settings?.enableInstantPlayer ?? true,
          viewMode: settings?.viewMode ?? LibraryViewMode.grid,
          emptyLabel: 'このフォルダに動画はありません',
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
