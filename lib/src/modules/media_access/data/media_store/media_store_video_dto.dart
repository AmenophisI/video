class MediaStoreVideoDto {
  const MediaStoreVideoDto({
    required this.mediaStoreId,
    required this.uri,
    required this.displayName,
    required this.folderId,
    required this.folderName,
    this.relativePath,
    this.mimeType,
    this.durationMs,
    this.sizeBytes,
    this.dateAddedAtMs,
    this.modifiedAtMs,
    this.width,
    this.height,
    this.rotationDegrees,
    this.bitrate,
    this.frameRate,
    this.metadataText,
    this.subtitleUri,
    this.isHdr = false,
    this.isDrm = false,
    this.isPlayable = true,
  });

  factory MediaStoreVideoDto.fromMap(Map<dynamic, dynamic> map) {
    final mediaStoreId = _intFrom(map['mediaStoreId']) ?? 0;
    final uriText = _stringFrom(map['uri']);

    return MediaStoreVideoDto(
      mediaStoreId: mediaStoreId,
      uri: Uri.parse(uriText ?? ''),
      displayName: _stringFrom(map['displayName']) ?? 'video-$mediaStoreId',
      folderId: _stringFrom(map['folderId']) ?? 'unknown',
      folderName: _stringFrom(map['folderName']) ?? 'Unknown',
      relativePath: _stringFrom(map['relativePath']),
      mimeType: _stringFrom(map['mimeType']),
      durationMs: _intFrom(map['durationMs']),
      sizeBytes: _intFrom(map['sizeBytes']),
      dateAddedAtMs: _intFrom(map['dateAddedAtMs']),
      modifiedAtMs: _intFrom(map['modifiedAtMs']),
      width: _intFrom(map['width']),
      height: _intFrom(map['height']),
      rotationDegrees: _intFrom(map['rotationDegrees']),
      bitrate: _intFrom(map['bitrate']),
      frameRate: _doubleFrom(map['frameRate']),
      metadataText: _stringFrom(map['metadataText']),
      subtitleUri: _uriFrom(map['subtitleUri']),
      isHdr: _boolFrom(map['isHdr']) ?? false,
      isDrm: _boolFrom(map['isDrm']) ?? false,
      isPlayable: _boolFrom(map['isPlayable']) ?? true,
    );
  }

  final int mediaStoreId;
  final Uri uri;
  final String displayName;
  final String folderId;
  final String folderName;
  final String? relativePath;
  final String? mimeType;
  final int? durationMs;
  final int? sizeBytes;
  final int? dateAddedAtMs;
  final int? modifiedAtMs;
  final int? width;
  final int? height;
  final int? rotationDegrees;
  final int? bitrate;
  final double? frameRate;
  final String? metadataText;
  final Uri? subtitleUri;
  final bool isHdr;
  final bool isDrm;
  final bool isPlayable;

  static String? _stringFrom(Object? value) {
    if (value == null) {
      return null;
    }

    return value.toString();
  }

  static int? _intFrom(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  static double? _doubleFrom(Object? value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static bool? _boolFrom(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is String) {
      return bool.tryParse(value);
    }

    return null;
  }

  static Uri? _uriFrom(Object? value) {
    final text = _stringFrom(value);
    if (text == null || text.isEmpty) {
      return null;
    }

    return Uri.tryParse(text);
  }
}
