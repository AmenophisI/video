class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.videoCount,
    this.representativeVideoId,
    this.latestModifiedAt,
    this.totalSizeBytes,
    this.storageLabel,
  });

  final String id;
  final String name;
  final int videoCount;
  final String? representativeVideoId;
  final DateTime? latestModifiedAt;
  final int? totalSizeBytes;
  final String? storageLabel;
}
