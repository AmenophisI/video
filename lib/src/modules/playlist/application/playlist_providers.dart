import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_preferences_playlist_repository.dart';
import '../domain/playlist.dart';
import '../domain/playlist_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final repository = SharedPreferencesPlaylistRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final playlistsProvider = StreamProvider<List<Playlist>>((ref) {
  return ref.watch(playlistRepositoryProvider).watchPlaylists();
});
