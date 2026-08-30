class Video {
  const Video({
    required this.id,
    required this.mediaStoreId,
    required this.uri,
    required this.displayName,
    required this.folderId,
    required this.folderName,
    this.relativePath,
    this.mimeType,
    this.duration,
    this.sizeBytes,
    this.width,
    this.height,
    this.rotationDegrees,
    this.bitrate,
    this.frameRate,
    this.videoCodec,
    this.audioCodec,
    this.audioChannelCount,
    this.createdAt,
    this.modifiedAt,
    this.thumbnailUri,
    this.subtitleUri,
    this.isHdr = false,
    this.is360Video = false,
    this.isSlowMotion = false,
    this.isHyperlapse = false,
    this.isDrm = false,
    this.isPlayable = true,
    this.isFavorite = false,
    this.isPrivate = false,
    this.lastPlayedPosition,
    this.lastPlayedAt,
  });

  final String id;
  final int mediaStoreId;
  final Uri uri;
  final String displayName;
  final String folderId;
  final String folderName;
  final String? relativePath;
  final String? mimeType;
  final Duration? duration;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? rotationDegrees;
  final int? bitrate;
  final double? frameRate;
  final String? videoCodec;
  final String? audioCodec;
  final int? audioChannelCount;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Uri? thumbnailUri;
  final Uri? subtitleUri;
  final bool isHdr;
  final bool is360Video;
  final bool isSlowMotion;
  final bool isHyperlapse;
  final bool isDrm;
  final bool isPlayable;
  final bool isFavorite;
  final bool isPrivate;
  final Duration? lastPlayedPosition;
  final DateTime? lastPlayedAt;

  double get playbackProgress {
    final durationMs = duration?.inMilliseconds ?? 0;
    final positionMs = lastPlayedPosition?.inMilliseconds ?? 0;

    if (durationMs <= 0 || positionMs <= 0) {
      return 0;
    }

    return (positionMs / durationMs).clamp(0, 1).toDouble();
  }

  bool get hasPlaybackProgress => playbackProgress > 0;

  String? get playbackUnavailableReason {
    if (isPlayable) {
      return null;
    }

    if (isDrm) {
      return 'DRM保護によりアプリ内で再生できません。外部プレイヤーまたは権利元のアプリで再生してください。';
    }

    return '対応していない形式、破損、または読み取り権限の問題により再生できません。';
  }

  List<String> get tags {
    return [
      if (isHdr) 'HDR',
      if (is360Video) '360度',
      if (isSlowMotion) 'スロー',
      if (isHyperlapse) 'Hyperlapse',
      if (isDrm) 'DRM',
      if (subtitleUri != null) '字幕',
      if (!isPlayable) '再生不可',
      if (isFavorite) 'お気に入り',
      if (isPrivate) '非表示',
    ];
  }

  Video copyWith({
    String? displayName,
    String? relativePath,
    bool? isFavorite,
    bool? isPrivate,
    Duration? lastPlayedPosition,
    DateTime? lastPlayedAt,
    bool clearPlaybackPosition = false,
  }) {
    return Video(
      id: id,
      mediaStoreId: mediaStoreId,
      uri: uri,
      displayName: displayName ?? this.displayName,
      folderId: folderId,
      folderName: folderName,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType,
      duration: duration,
      sizeBytes: sizeBytes,
      width: width,
      height: height,
      rotationDegrees: rotationDegrees,
      bitrate: bitrate,
      frameRate: frameRate,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      audioChannelCount: audioChannelCount,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      thumbnailUri: thumbnailUri,
      subtitleUri: subtitleUri,
      isHdr: isHdr,
      is360Video: is360Video,
      isSlowMotion: isSlowMotion,
      isHyperlapse: isHyperlapse,
      isDrm: isDrm,
      isPlayable: isPlayable,
      isFavorite: isFavorite ?? this.isFavorite,
      isPrivate: isPrivate ?? this.isPrivate,
      lastPlayedPosition: clearPlaybackPosition
          ? null
          : lastPlayedPosition ?? this.lastPlayedPosition,
      lastPlayedAt:
          clearPlaybackPosition ? null : lastPlayedAt ?? this.lastPlayedAt,
    );
  }
}
