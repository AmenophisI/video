class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.videoIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get videoCount => videoIds.length;

  Playlist copyWith({
    String? name,
    List<String>? videoIds,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      videoIds: videoIds ?? this.videoIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
