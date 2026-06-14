import 'playlist.dart';

abstract interface class PlaylistRepository {
  Stream<List<Playlist>> watchPlaylists();

  Future<Playlist> createPlaylist(String name);

  Future<void> renamePlaylist({
    required String playlistId,
    required String name,
  });

  Future<void> deletePlaylist(String playlistId);

  Future<void> addVideo({
    required String playlistId,
    required String videoId,
  });

  Future<void> removeVideo({
    required String playlistId,
    required String videoId,
  });

  Future<void> reorderVideos({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  });
}
