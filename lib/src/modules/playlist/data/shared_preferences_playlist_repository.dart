import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/playlist.dart';
import '../domain/playlist_repository.dart';

class SharedPreferencesPlaylistRepository implements PlaylistRepository {
  SharedPreferencesPlaylistRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  final StreamController<List<Playlist>> _controller =
      StreamController<List<Playlist>>.broadcast();

  @override
  Stream<List<Playlist>> watchPlaylists() async* {
    yield await _load();
    yield* _controller.stream;
  }

  @override
  Future<Playlist> createPlaylist(String name) async {
    final normalized = name.trim();
    final now = DateTime.now();
    final playlist = Playlist(
      id: now.microsecondsSinceEpoch.toString(),
      name: normalized.isEmpty ? '新しいプレイリスト' : normalized,
      videoIds: const [],
      createdAt: now,
      updatedAt: now,
    );

    final playlists = [...await _load(), playlist];
    await _save(playlists);
    return playlist;
  }

  @override
  Future<void> renamePlaylist({
    required String playlistId,
    required String name,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _update(playlistId, (playlist) {
      return playlist.copyWith(name: normalized, updatedAt: DateTime.now());
    });
  }

  @override
  Future<void> deletePlaylist(String playlistId) async {
    final playlists = await _load();
    await _save(
      playlists.where((playlist) => playlist.id != playlistId).toList(),
    );
  }

  @override
  Future<void> addVideo({
    required String playlistId,
    required String videoId,
  }) async {
    await _update(playlistId, (playlist) {
      if (playlist.videoIds.contains(videoId)) {
        return playlist;
      }

      return playlist.copyWith(
        videoIds: [...playlist.videoIds, videoId],
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<void> removeVideo({
    required String playlistId,
    required String videoId,
  }) async {
    await _update(playlistId, (playlist) {
      return playlist.copyWith(
        videoIds: playlist.videoIds.where((id) => id != videoId).toList(),
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<void> reorderVideos({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) async {
    await _update(playlistId, (playlist) {
      final videoIds = [...playlist.videoIds];
      if (oldIndex < 0 ||
          oldIndex >= videoIds.length ||
          newIndex < 0 ||
          newIndex > videoIds.length) {
        return playlist;
      }

      final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final videoId = videoIds.removeAt(oldIndex);
      videoIds.insert(adjustedNewIndex, videoId);

      return playlist.copyWith(
        videoIds: videoIds,
        updatedAt: DateTime.now(),
      );
    });
  }

  void dispose() {
    _controller.close();
  }

  Future<void> _update(
    String playlistId,
    Playlist Function(Playlist playlist) update,
  ) async {
    final playlists = await _load();
    final next = [
      for (final playlist in playlists)
        if (playlist.id == playlistId) update(playlist) else playlist,
    ];
    await _save(next);
  }

  Future<List<Playlist>> _load() async {
    final encoded = await _preferences.getStringList(_playlistsKey) ?? const [];
    final playlists = <Playlist>[];

    for (final item in encoded) {
      final decoded = jsonDecode(item);
      if (decoded is! Map<String, Object?>) {
        continue;
      }

      playlists.add(
        Playlist(
          id: decoded['id']?.toString() ?? '',
          name: decoded['name']?.toString() ?? 'プレイリスト',
          videoIds: [
            for (final id in decoded['videoIds'] as List? ?? const [])
              id.toString(),
          ],
          createdAt:
              DateTime.tryParse(decoded['createdAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt:
              DateTime.tryParse(decoded['updatedAt']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    }

    playlists.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return playlists;
  }

  Future<void> _save(List<Playlist> playlists) async {
    await _preferences.setStringList(
      _playlistsKey,
      [
        for (final playlist in playlists)
          jsonEncode({
            'id': playlist.id,
            'name': playlist.name,
            'videoIds': playlist.videoIds,
            'createdAt': playlist.createdAt.toIso8601String(),
            'updatedAt': playlist.updatedAt.toIso8601String(),
          }),
      ],
    );

    if (!_controller.isClosed) {
      _controller.add(await _load());
    }
  }

  static const _playlistsKey = 'playlist.items';
}
