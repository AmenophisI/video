import 'package:shared_preferences/shared_preferences.dart';

class SavedPlaybackPosition {
  const SavedPlaybackPosition({
    required this.position,
    required this.playedAt,
  });

  final Duration position;
  final DateTime playedAt;
}

class SharedPreferencesPlaybackPositionStore {
  SharedPreferencesPlaybackPositionStore({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<SavedPlaybackPosition?> getPosition(String videoId) async {
    final positionMs = await _preferences.getInt(_positionKey(videoId));
    if (positionMs == null || positionMs <= 0) {
      return null;
    }

    final playedAtMs = await _preferences.getInt(_playedAtKey(videoId));

    return SavedPlaybackPosition(
      position: Duration(milliseconds: positionMs),
      playedAt: DateTime.fromMillisecondsSinceEpoch(
        playedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<Map<String, SavedPlaybackPosition>> getPositions(
    Iterable<String> videoIds,
  ) async {
    final entries = <String, SavedPlaybackPosition>{};

    for (final videoId in videoIds) {
      final position = await getPosition(videoId);
      if (position != null) {
        entries[videoId] = position;
      }
    }

    return entries;
  }

  Future<void> savePosition({
    required String videoId,
    required Duration position,
    required DateTime playedAt,
  }) async {
    await Future.wait([
      _preferences.setInt(_positionKey(videoId), position.inMilliseconds),
      _preferences.setInt(
          _playedAtKey(videoId), playedAt.millisecondsSinceEpoch),
    ]);
  }

  static String _positionKey(String videoId) {
    return 'playback.$videoId.positionMs';
  }

  static String _playedAtKey(String videoId) {
    return 'playback.$videoId.playedAtMs';
  }
}
