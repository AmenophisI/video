import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/duration_format.dart';
import '../../playback/presentation/full_screen_player_screen.dart';
import '../../settings/application/settings_providers.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../../video/domain/video_query.dart';
import '../../video/presentation/widgets/video_tile.dart';
import '../application/playlist_providers.dart';
import '../domain/playlist.dart';

class PlaylistListScreen extends ConsumerWidget {
  const PlaylistListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      body: playlistsAsync.when(
        data: (playlists) {
          if (playlists.isEmpty) {
            return const Center(child: Text('プレイリストがありません'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final playlist = playlists[index];

              return ListTile(
                leading: const Icon(Icons.playlist_play),
                title: Text(playlist.name),
                subtitle: Text('${playlist.videoCount}件の動画'),
                trailing: PopupMenuButton<_PlaylistAction>(
                  onSelected: (action) async {
                    switch (action) {
                      case _PlaylistAction.rename:
                        await _showRenameDialog(context, ref, playlist);
                      case _PlaylistAction.delete:
                        await ref
                            .read(playlistRepositoryProvider)
                            .deletePlaylist(playlist.id);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _PlaylistAction.rename,
                      child: Text('名前変更'),
                    ),
                    PopupMenuItem(
                      value: _PlaylistAction.delete,
                      child: Text('削除'),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlaylistVideosScreen(
                        playlistId: playlist.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('作成'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレイリスト作成'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名前'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('作成'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null) {
      return;
    }

    await ref.read(playlistRepositoryProvider).createPlaylist(name);
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プレイリスト名を変更'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '名前'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (name == null || name.isEmpty) {
      return;
    }

    await ref.read(playlistRepositoryProvider).renamePlaylist(
          playlistId: playlist.id,
          name: name,
        );
  }
}

class PlaylistVideosScreen extends ConsumerWidget {
  const PlaylistVideosScreen({
    required this.playlistId,
    super.key,
  });

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);
    final videosAsync = ref.watch(_allVideosProvider);
    final settings = ref.watch(appSettingsProvider).valueOrNull;

    return playlistsAsync.when(
      data: (playlists) {
        final playlist = playlists
            .where((playlist) => playlist.id == playlistId)
            .firstOrNull;
        if (playlist == null) {
          return const Scaffold(
            body: Center(child: Text('プレイリストが見つかりません')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(playlist.name),
            actions: [
              IconButton(
                tooltip: '先頭から再生',
                onPressed: playlist.videoIds.isEmpty
                    ? null
                    : () => _openPlaylistPlayer(
                          context,
                          playlist.videoIds,
                          0,
                        ),
                icon: const Icon(Icons.play_arrow),
              ),
            ],
          ),
          body: videosAsync.when(
            data: (videos) {
              final byId = {for (final video in videos) video.id: video};
              final playlistVideos = <Video>[
                for (final id in playlist.videoIds)
                  if (byId[id] != null) byId[id]!,
              ];

              if (playlistVideos.isEmpty) {
                return const Center(child: Text('動画がありません'));
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: playlistVideos.length,
                onReorder: (oldIndex, newIndex) async {
                  await ref.read(playlistRepositoryProvider).reorderVideos(
                        playlistId: playlist.id,
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                      );
                },
                itemBuilder: (context, index) {
                  final video = playlistVideos[index];

                  return Padding(
                    key: ValueKey(video.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      height: 260,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: VideoTile(
                              video: video,
                              showPlaybackProgress:
                                  settings?.showPlaybackProgress ?? true,
                              showTags: settings?.showVideoTags ?? true,
                              onTap: () => _openPlaylistPlayer(
                                context,
                                playlist.videoIds,
                                index,
                              ),
                              onLongPress: () => _removeVideo(
                                context,
                                ref,
                                playlist,
                                video,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'リストから削除',
                                    onPressed: () => _removeVideo(
                                      context,
                                      ref,
                                      playlist,
                                      video,
                                    ),
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.drag_handle),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            error: (error, _) => Center(child: Text(error.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${playlist.videoCount}件 / 更新 ${formatDate(playlist.updatedAt)}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _removeVideo(
    BuildContext context,
    WidgetRef ref,
    Playlist playlist,
    Video video,
  ) async {
    await ref.read(playlistRepositoryProvider).removeVideo(
          playlistId: playlist.id,
          videoId: video.id,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${video.displayName} をリストから削除しました')),
      );
    }
  }

  void _openPlaylistPlayer(
    BuildContext context,
    List<String> videoIds,
    int index,
  ) {
    if (videoIds.isEmpty || index < 0 || index >= videoIds.length) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenPlayerScreen(
          videoId: videoIds[index],
          playlistVideoIds: videoIds,
          playlistInitialIndex: index,
        ),
      ),
    );
  }
}

enum _PlaylistAction {
  rename,
  delete,
}

final _allVideosProvider = StreamProvider.autoDispose<List<Video>>((ref) {
  return ref.watch(videoRepositoryProvider).watchVideos(const VideoQuery());
});
