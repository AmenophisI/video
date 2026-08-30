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

    return playlistsAsync.when(
      data: (playlists) {
        if (playlists.isEmpty) {
          return const Center(child: Text('プレイリストがありません'));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 24),
          itemCount: playlists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 2),
          itemBuilder: (context, index) {
            final playlist = playlists[index];

            return _PlaylistRow(
              playlist: playlist,
              color: _playlistAccent(index),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlaylistVideosScreen(
                      playlistId: playlist.id,
                    ),
                  ),
                );
              },
              onActionSelected: (action) async {
                switch (action) {
                  case _PlaylistAction.rename:
                    await _showRenameDialog(context, ref, playlist);
                  case _PlaylistAction.delete:
                    await ref
                        .read(playlistRepositoryProvider)
                        .deletePlaylist(playlist.id);
                }
              },
            );
          },
        );
      },
      error: (error, _) => Center(child: Text(error.toString())),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
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

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.color,
    required this.onTap,
    required this.onActionSelected,
  });

  final Playlist playlist;
  final Color color;
  final VoidCallback onTap;
  final ValueChanged<_PlaylistAction> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: '${playlist.name}、${playlist.videoCount}件の動画',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color,
                        Color.alphaBlend(
                          Colors.black.withValues(alpha: 0.28),
                          color,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.playlist_play,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${playlist.videoCount}件の動画',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_PlaylistAction>(
                  tooltip: 'プレイリスト操作',
                  onSelected: onActionSelected,
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
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 21,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _playlistAccent(int index) {
  const colors = [
    Color(0xFF0F766E),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFF2563EB),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
  ];

  return colors[index % colors.length];
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
