// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VideoIndexEntriesTable extends VideoIndexEntries
    with TableInfo<$VideoIndexEntriesTable, VideoIndexEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoIndexEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaStoreIdMeta =
      const VerificationMeta('mediaStoreId');
  @override
  late final GeneratedColumn<int> mediaStoreId = GeneratedColumn<int>(
      'media_store_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
      'uri', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderIdMeta =
      const VerificationMeta('folderId');
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
      'folder_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _folderNameMeta =
      const VerificationMeta('folderName');
  @override
  late final GeneratedColumn<String> folderName = GeneratedColumn<String>(
      'folder_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _rotationDegreesMeta =
      const VerificationMeta('rotationDegrees');
  @override
  late final GeneratedColumn<int> rotationDegrees = GeneratedColumn<int>(
      'rotation_degrees', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _bitrateMeta =
      const VerificationMeta('bitrate');
  @override
  late final GeneratedColumn<int> bitrate = GeneratedColumn<int>(
      'bitrate', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _frameRateMeta =
      const VerificationMeta('frameRate');
  @override
  late final GeneratedColumn<double> frameRate = GeneratedColumn<double>(
      'frame_rate', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _subtitleUriMeta =
      const VerificationMeta('subtitleUri');
  @override
  late final GeneratedColumn<String> subtitleUri = GeneratedColumn<String>(
      'subtitle_uri', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMsMeta =
      const VerificationMeta('createdAtMs');
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
      'created_at_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _modifiedAtMsMeta =
      const VerificationMeta('modifiedAtMs');
  @override
  late final GeneratedColumn<int> modifiedAtMs = GeneratedColumn<int>(
      'modified_at_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _isHdrMeta = const VerificationMeta('isHdr');
  @override
  late final GeneratedColumn<bool> isHdr = GeneratedColumn<bool>(
      'is_hdr', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_hdr" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _is360VideoMeta =
      const VerificationMeta('is360Video');
  @override
  late final GeneratedColumn<bool> is360Video = GeneratedColumn<bool>(
      'is360_video', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is360_video" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSlowMotionMeta =
      const VerificationMeta('isSlowMotion');
  @override
  late final GeneratedColumn<bool> isSlowMotion = GeneratedColumn<bool>(
      'is_slow_motion', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_slow_motion" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isHyperlapseMeta =
      const VerificationMeta('isHyperlapse');
  @override
  late final GeneratedColumn<bool> isHyperlapse = GeneratedColumn<bool>(
      'is_hyperlapse', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_hyperlapse" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isDrmMeta = const VerificationMeta('isDrm');
  @override
  late final GeneratedColumn<bool> isDrm = GeneratedColumn<bool>(
      'is_drm', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_drm" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPlayableMeta =
      const VerificationMeta('isPlayable');
  @override
  late final GeneratedColumn<bool> isPlayable = GeneratedColumn<bool>(
      'is_playable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_playable" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isFavoriteMeta =
      const VerificationMeta('isFavorite');
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
      'is_favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isPrivateMeta =
      const VerificationMeta('isPrivate');
  @override
  late final GeneratedColumn<bool> isPrivate = GeneratedColumn<bool>(
      'is_private', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_private" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastPlayedPositionMsMeta =
      const VerificationMeta('lastPlayedPositionMs');
  @override
  late final GeneratedColumn<int> lastPlayedPositionMs = GeneratedColumn<int>(
      'last_played_position_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastPlayedAtMsMeta =
      const VerificationMeta('lastPlayedAtMs');
  @override
  late final GeneratedColumn<int> lastPlayedAtMs = GeneratedColumn<int>(
      'last_played_at_ms', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mediaStoreId,
        uri,
        displayName,
        folderId,
        folderName,
        relativePath,
        mimeType,
        durationMs,
        sizeBytes,
        width,
        height,
        rotationDegrees,
        bitrate,
        frameRate,
        subtitleUri,
        createdAtMs,
        modifiedAtMs,
        isHdr,
        is360Video,
        isSlowMotion,
        isHyperlapse,
        isDrm,
        isPlayable,
        isFavorite,
        isPrivate,
        lastPlayedPositionMs,
        lastPlayedAtMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_index_entries';
  @override
  VerificationContext validateIntegrity(Insertable<VideoIndexEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_store_id')) {
      context.handle(
          _mediaStoreIdMeta,
          mediaStoreId.isAcceptableOrUnknown(
              data['media_store_id']!, _mediaStoreIdMeta));
    } else if (isInserting) {
      context.missing(_mediaStoreIdMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
          _uriMeta, uri.isAcceptableOrUnknown(data['uri']!, _uriMeta));
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(_folderIdMeta,
          folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta));
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('folder_name')) {
      context.handle(
          _folderNameMeta,
          folderName.isAcceptableOrUnknown(
              data['folder_name']!, _folderNameMeta));
    } else if (isInserting) {
      context.missing(_folderNameMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('rotation_degrees')) {
      context.handle(
          _rotationDegreesMeta,
          rotationDegrees.isAcceptableOrUnknown(
              data['rotation_degrees']!, _rotationDegreesMeta));
    }
    if (data.containsKey('bitrate')) {
      context.handle(_bitrateMeta,
          bitrate.isAcceptableOrUnknown(data['bitrate']!, _bitrateMeta));
    }
    if (data.containsKey('frame_rate')) {
      context.handle(_frameRateMeta,
          frameRate.isAcceptableOrUnknown(data['frame_rate']!, _frameRateMeta));
    }
    if (data.containsKey('subtitle_uri')) {
      context.handle(
          _subtitleUriMeta,
          subtitleUri.isAcceptableOrUnknown(
              data['subtitle_uri']!, _subtitleUriMeta));
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
          _createdAtMsMeta,
          createdAtMs.isAcceptableOrUnknown(
              data['created_at_ms']!, _createdAtMsMeta));
    }
    if (data.containsKey('modified_at_ms')) {
      context.handle(
          _modifiedAtMsMeta,
          modifiedAtMs.isAcceptableOrUnknown(
              data['modified_at_ms']!, _modifiedAtMsMeta));
    }
    if (data.containsKey('is_hdr')) {
      context.handle(
          _isHdrMeta, isHdr.isAcceptableOrUnknown(data['is_hdr']!, _isHdrMeta));
    }
    if (data.containsKey('is360_video')) {
      context.handle(
          _is360VideoMeta,
          is360Video.isAcceptableOrUnknown(
              data['is360_video']!, _is360VideoMeta));
    }
    if (data.containsKey('is_slow_motion')) {
      context.handle(
          _isSlowMotionMeta,
          isSlowMotion.isAcceptableOrUnknown(
              data['is_slow_motion']!, _isSlowMotionMeta));
    }
    if (data.containsKey('is_hyperlapse')) {
      context.handle(
          _isHyperlapseMeta,
          isHyperlapse.isAcceptableOrUnknown(
              data['is_hyperlapse']!, _isHyperlapseMeta));
    }
    if (data.containsKey('is_drm')) {
      context.handle(
          _isDrmMeta, isDrm.isAcceptableOrUnknown(data['is_drm']!, _isDrmMeta));
    }
    if (data.containsKey('is_playable')) {
      context.handle(
          _isPlayableMeta,
          isPlayable.isAcceptableOrUnknown(
              data['is_playable']!, _isPlayableMeta));
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
          _isFavoriteMeta,
          isFavorite.isAcceptableOrUnknown(
              data['is_favorite']!, _isFavoriteMeta));
    }
    if (data.containsKey('is_private')) {
      context.handle(_isPrivateMeta,
          isPrivate.isAcceptableOrUnknown(data['is_private']!, _isPrivateMeta));
    }
    if (data.containsKey('last_played_position_ms')) {
      context.handle(
          _lastPlayedPositionMsMeta,
          lastPlayedPositionMs.isAcceptableOrUnknown(
              data['last_played_position_ms']!, _lastPlayedPositionMsMeta));
    }
    if (data.containsKey('last_played_at_ms')) {
      context.handle(
          _lastPlayedAtMsMeta,
          lastPlayedAtMs.isAcceptableOrUnknown(
              data['last_played_at_ms']!, _lastPlayedAtMsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoIndexEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoIndexEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mediaStoreId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}media_store_id'])!,
      uri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}uri'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      folderId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_id'])!,
      folderName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}folder_name'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      rotationDegrees: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rotation_degrees']),
      bitrate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bitrate']),
      frameRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}frame_rate']),
      subtitleUri: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtitle_uri']),
      createdAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_ms']),
      modifiedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}modified_at_ms']),
      isHdr: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hdr'])!,
      is360Video: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is360_video'])!,
      isSlowMotion: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_slow_motion'])!,
      isHyperlapse: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_hyperlapse'])!,
      isDrm: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_drm'])!,
      isPlayable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_playable'])!,
      isFavorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_favorite'])!,
      isPrivate: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_private'])!,
      lastPlayedPositionMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_played_position_ms']),
      lastPlayedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_played_at_ms']),
    );
  }

  @override
  $VideoIndexEntriesTable createAlias(String alias) {
    return $VideoIndexEntriesTable(attachedDatabase, alias);
  }
}

class VideoIndexEntry extends DataClass implements Insertable<VideoIndexEntry> {
  final String id;
  final int mediaStoreId;
  final String uri;
  final String displayName;
  final String folderId;
  final String folderName;
  final String? relativePath;
  final String? mimeType;
  final int? durationMs;
  final int? sizeBytes;
  final int? width;
  final int? height;
  final int? rotationDegrees;
  final int? bitrate;
  final double? frameRate;
  final String? subtitleUri;
  final int? createdAtMs;
  final int? modifiedAtMs;
  final bool isHdr;
  final bool is360Video;
  final bool isSlowMotion;
  final bool isHyperlapse;
  final bool isDrm;
  final bool isPlayable;
  final bool isFavorite;
  final bool isPrivate;
  final int? lastPlayedPositionMs;
  final int? lastPlayedAtMs;
  const VideoIndexEntry(
      {required this.id,
      required this.mediaStoreId,
      required this.uri,
      required this.displayName,
      required this.folderId,
      required this.folderName,
      this.relativePath,
      this.mimeType,
      this.durationMs,
      this.sizeBytes,
      this.width,
      this.height,
      this.rotationDegrees,
      this.bitrate,
      this.frameRate,
      this.subtitleUri,
      this.createdAtMs,
      this.modifiedAtMs,
      required this.isHdr,
      required this.is360Video,
      required this.isSlowMotion,
      required this.isHyperlapse,
      required this.isDrm,
      required this.isPlayable,
      required this.isFavorite,
      required this.isPrivate,
      this.lastPlayedPositionMs,
      this.lastPlayedAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_store_id'] = Variable<int>(mediaStoreId);
    map['uri'] = Variable<String>(uri);
    map['display_name'] = Variable<String>(displayName);
    map['folder_id'] = Variable<String>(folderId);
    map['folder_name'] = Variable<String>(folderName);
    if (!nullToAbsent || relativePath != null) {
      map['relative_path'] = Variable<String>(relativePath);
    }
    if (!nullToAbsent || mimeType != null) {
      map['mime_type'] = Variable<String>(mimeType);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || rotationDegrees != null) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees);
    }
    if (!nullToAbsent || bitrate != null) {
      map['bitrate'] = Variable<int>(bitrate);
    }
    if (!nullToAbsent || frameRate != null) {
      map['frame_rate'] = Variable<double>(frameRate);
    }
    if (!nullToAbsent || subtitleUri != null) {
      map['subtitle_uri'] = Variable<String>(subtitleUri);
    }
    if (!nullToAbsent || createdAtMs != null) {
      map['created_at_ms'] = Variable<int>(createdAtMs);
    }
    if (!nullToAbsent || modifiedAtMs != null) {
      map['modified_at_ms'] = Variable<int>(modifiedAtMs);
    }
    map['is_hdr'] = Variable<bool>(isHdr);
    map['is360_video'] = Variable<bool>(is360Video);
    map['is_slow_motion'] = Variable<bool>(isSlowMotion);
    map['is_hyperlapse'] = Variable<bool>(isHyperlapse);
    map['is_drm'] = Variable<bool>(isDrm);
    map['is_playable'] = Variable<bool>(isPlayable);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_private'] = Variable<bool>(isPrivate);
    if (!nullToAbsent || lastPlayedPositionMs != null) {
      map['last_played_position_ms'] = Variable<int>(lastPlayedPositionMs);
    }
    if (!nullToAbsent || lastPlayedAtMs != null) {
      map['last_played_at_ms'] = Variable<int>(lastPlayedAtMs);
    }
    return map;
  }

  VideoIndexEntriesCompanion toCompanion(bool nullToAbsent) {
    return VideoIndexEntriesCompanion(
      id: Value(id),
      mediaStoreId: Value(mediaStoreId),
      uri: Value(uri),
      displayName: Value(displayName),
      folderId: Value(folderId),
      folderName: Value(folderName),
      relativePath: relativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(relativePath),
      mimeType: mimeType == null && nullToAbsent
          ? const Value.absent()
          : Value(mimeType),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      rotationDegrees: rotationDegrees == null && nullToAbsent
          ? const Value.absent()
          : Value(rotationDegrees),
      bitrate: bitrate == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrate),
      frameRate: frameRate == null && nullToAbsent
          ? const Value.absent()
          : Value(frameRate),
      subtitleUri: subtitleUri == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitleUri),
      createdAtMs: createdAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAtMs),
      modifiedAtMs: modifiedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(modifiedAtMs),
      isHdr: Value(isHdr),
      is360Video: Value(is360Video),
      isSlowMotion: Value(isSlowMotion),
      isHyperlapse: Value(isHyperlapse),
      isDrm: Value(isDrm),
      isPlayable: Value(isPlayable),
      isFavorite: Value(isFavorite),
      isPrivate: Value(isPrivate),
      lastPlayedPositionMs: lastPlayedPositionMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedPositionMs),
      lastPlayedAtMs: lastPlayedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAtMs),
    );
  }

  factory VideoIndexEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoIndexEntry(
      id: serializer.fromJson<String>(json['id']),
      mediaStoreId: serializer.fromJson<int>(json['mediaStoreId']),
      uri: serializer.fromJson<String>(json['uri']),
      displayName: serializer.fromJson<String>(json['displayName']),
      folderId: serializer.fromJson<String>(json['folderId']),
      folderName: serializer.fromJson<String>(json['folderName']),
      relativePath: serializer.fromJson<String?>(json['relativePath']),
      mimeType: serializer.fromJson<String?>(json['mimeType']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      rotationDegrees: serializer.fromJson<int?>(json['rotationDegrees']),
      bitrate: serializer.fromJson<int?>(json['bitrate']),
      frameRate: serializer.fromJson<double?>(json['frameRate']),
      subtitleUri: serializer.fromJson<String?>(json['subtitleUri']),
      createdAtMs: serializer.fromJson<int?>(json['createdAtMs']),
      modifiedAtMs: serializer.fromJson<int?>(json['modifiedAtMs']),
      isHdr: serializer.fromJson<bool>(json['isHdr']),
      is360Video: serializer.fromJson<bool>(json['is360Video']),
      isSlowMotion: serializer.fromJson<bool>(json['isSlowMotion']),
      isHyperlapse: serializer.fromJson<bool>(json['isHyperlapse']),
      isDrm: serializer.fromJson<bool>(json['isDrm']),
      isPlayable: serializer.fromJson<bool>(json['isPlayable']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isPrivate: serializer.fromJson<bool>(json['isPrivate']),
      lastPlayedPositionMs:
          serializer.fromJson<int?>(json['lastPlayedPositionMs']),
      lastPlayedAtMs: serializer.fromJson<int?>(json['lastPlayedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaStoreId': serializer.toJson<int>(mediaStoreId),
      'uri': serializer.toJson<String>(uri),
      'displayName': serializer.toJson<String>(displayName),
      'folderId': serializer.toJson<String>(folderId),
      'folderName': serializer.toJson<String>(folderName),
      'relativePath': serializer.toJson<String?>(relativePath),
      'mimeType': serializer.toJson<String?>(mimeType),
      'durationMs': serializer.toJson<int?>(durationMs),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'rotationDegrees': serializer.toJson<int?>(rotationDegrees),
      'bitrate': serializer.toJson<int?>(bitrate),
      'frameRate': serializer.toJson<double?>(frameRate),
      'subtitleUri': serializer.toJson<String?>(subtitleUri),
      'createdAtMs': serializer.toJson<int?>(createdAtMs),
      'modifiedAtMs': serializer.toJson<int?>(modifiedAtMs),
      'isHdr': serializer.toJson<bool>(isHdr),
      'is360Video': serializer.toJson<bool>(is360Video),
      'isSlowMotion': serializer.toJson<bool>(isSlowMotion),
      'isHyperlapse': serializer.toJson<bool>(isHyperlapse),
      'isDrm': serializer.toJson<bool>(isDrm),
      'isPlayable': serializer.toJson<bool>(isPlayable),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isPrivate': serializer.toJson<bool>(isPrivate),
      'lastPlayedPositionMs': serializer.toJson<int?>(lastPlayedPositionMs),
      'lastPlayedAtMs': serializer.toJson<int?>(lastPlayedAtMs),
    };
  }

  VideoIndexEntry copyWith(
          {String? id,
          int? mediaStoreId,
          String? uri,
          String? displayName,
          String? folderId,
          String? folderName,
          Value<String?> relativePath = const Value.absent(),
          Value<String?> mimeType = const Value.absent(),
          Value<int?> durationMs = const Value.absent(),
          Value<int?> sizeBytes = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<int?> rotationDegrees = const Value.absent(),
          Value<int?> bitrate = const Value.absent(),
          Value<double?> frameRate = const Value.absent(),
          Value<String?> subtitleUri = const Value.absent(),
          Value<int?> createdAtMs = const Value.absent(),
          Value<int?> modifiedAtMs = const Value.absent(),
          bool? isHdr,
          bool? is360Video,
          bool? isSlowMotion,
          bool? isHyperlapse,
          bool? isDrm,
          bool? isPlayable,
          bool? isFavorite,
          bool? isPrivate,
          Value<int?> lastPlayedPositionMs = const Value.absent(),
          Value<int?> lastPlayedAtMs = const Value.absent()}) =>
      VideoIndexEntry(
        id: id ?? this.id,
        mediaStoreId: mediaStoreId ?? this.mediaStoreId,
        uri: uri ?? this.uri,
        displayName: displayName ?? this.displayName,
        folderId: folderId ?? this.folderId,
        folderName: folderName ?? this.folderName,
        relativePath:
            relativePath.present ? relativePath.value : this.relativePath,
        mimeType: mimeType.present ? mimeType.value : this.mimeType,
        durationMs: durationMs.present ? durationMs.value : this.durationMs,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        rotationDegrees: rotationDegrees.present
            ? rotationDegrees.value
            : this.rotationDegrees,
        bitrate: bitrate.present ? bitrate.value : this.bitrate,
        frameRate: frameRate.present ? frameRate.value : this.frameRate,
        subtitleUri: subtitleUri.present ? subtitleUri.value : this.subtitleUri,
        createdAtMs: createdAtMs.present ? createdAtMs.value : this.createdAtMs,
        modifiedAtMs:
            modifiedAtMs.present ? modifiedAtMs.value : this.modifiedAtMs,
        isHdr: isHdr ?? this.isHdr,
        is360Video: is360Video ?? this.is360Video,
        isSlowMotion: isSlowMotion ?? this.isSlowMotion,
        isHyperlapse: isHyperlapse ?? this.isHyperlapse,
        isDrm: isDrm ?? this.isDrm,
        isPlayable: isPlayable ?? this.isPlayable,
        isFavorite: isFavorite ?? this.isFavorite,
        isPrivate: isPrivate ?? this.isPrivate,
        lastPlayedPositionMs: lastPlayedPositionMs.present
            ? lastPlayedPositionMs.value
            : this.lastPlayedPositionMs,
        lastPlayedAtMs:
            lastPlayedAtMs.present ? lastPlayedAtMs.value : this.lastPlayedAtMs,
      );
  VideoIndexEntry copyWithCompanion(VideoIndexEntriesCompanion data) {
    return VideoIndexEntry(
      id: data.id.present ? data.id.value : this.id,
      mediaStoreId: data.mediaStoreId.present
          ? data.mediaStoreId.value
          : this.mediaStoreId,
      uri: data.uri.present ? data.uri.value : this.uri,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      folderName:
          data.folderName.present ? data.folderName.value : this.folderName,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      rotationDegrees: data.rotationDegrees.present
          ? data.rotationDegrees.value
          : this.rotationDegrees,
      bitrate: data.bitrate.present ? data.bitrate.value : this.bitrate,
      frameRate: data.frameRate.present ? data.frameRate.value : this.frameRate,
      subtitleUri:
          data.subtitleUri.present ? data.subtitleUri.value : this.subtitleUri,
      createdAtMs:
          data.createdAtMs.present ? data.createdAtMs.value : this.createdAtMs,
      modifiedAtMs: data.modifiedAtMs.present
          ? data.modifiedAtMs.value
          : this.modifiedAtMs,
      isHdr: data.isHdr.present ? data.isHdr.value : this.isHdr,
      is360Video:
          data.is360Video.present ? data.is360Video.value : this.is360Video,
      isSlowMotion: data.isSlowMotion.present
          ? data.isSlowMotion.value
          : this.isSlowMotion,
      isHyperlapse: data.isHyperlapse.present
          ? data.isHyperlapse.value
          : this.isHyperlapse,
      isDrm: data.isDrm.present ? data.isDrm.value : this.isDrm,
      isPlayable:
          data.isPlayable.present ? data.isPlayable.value : this.isPlayable,
      isFavorite:
          data.isFavorite.present ? data.isFavorite.value : this.isFavorite,
      isPrivate: data.isPrivate.present ? data.isPrivate.value : this.isPrivate,
      lastPlayedPositionMs: data.lastPlayedPositionMs.present
          ? data.lastPlayedPositionMs.value
          : this.lastPlayedPositionMs,
      lastPlayedAtMs: data.lastPlayedAtMs.present
          ? data.lastPlayedAtMs.value
          : this.lastPlayedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoIndexEntry(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('folderId: $folderId, ')
          ..write('folderName: $folderName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('bitrate: $bitrate, ')
          ..write('frameRate: $frameRate, ')
          ..write('subtitleUri: $subtitleUri, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('isHdr: $isHdr, ')
          ..write('is360Video: $is360Video, ')
          ..write('isSlowMotion: $isSlowMotion, ')
          ..write('isHyperlapse: $isHyperlapse, ')
          ..write('isDrm: $isDrm, ')
          ..write('isPlayable: $isPlayable, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('lastPlayedPositionMs: $lastPlayedPositionMs, ')
          ..write('lastPlayedAtMs: $lastPlayedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        mediaStoreId,
        uri,
        displayName,
        folderId,
        folderName,
        relativePath,
        mimeType,
        durationMs,
        sizeBytes,
        width,
        height,
        rotationDegrees,
        bitrate,
        frameRate,
        subtitleUri,
        createdAtMs,
        modifiedAtMs,
        isHdr,
        is360Video,
        isSlowMotion,
        isHyperlapse,
        isDrm,
        isPlayable,
        isFavorite,
        isPrivate,
        lastPlayedPositionMs,
        lastPlayedAtMs
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoIndexEntry &&
          other.id == this.id &&
          other.mediaStoreId == this.mediaStoreId &&
          other.uri == this.uri &&
          other.displayName == this.displayName &&
          other.folderId == this.folderId &&
          other.folderName == this.folderName &&
          other.relativePath == this.relativePath &&
          other.mimeType == this.mimeType &&
          other.durationMs == this.durationMs &&
          other.sizeBytes == this.sizeBytes &&
          other.width == this.width &&
          other.height == this.height &&
          other.rotationDegrees == this.rotationDegrees &&
          other.bitrate == this.bitrate &&
          other.frameRate == this.frameRate &&
          other.subtitleUri == this.subtitleUri &&
          other.createdAtMs == this.createdAtMs &&
          other.modifiedAtMs == this.modifiedAtMs &&
          other.isHdr == this.isHdr &&
          other.is360Video == this.is360Video &&
          other.isSlowMotion == this.isSlowMotion &&
          other.isHyperlapse == this.isHyperlapse &&
          other.isDrm == this.isDrm &&
          other.isPlayable == this.isPlayable &&
          other.isFavorite == this.isFavorite &&
          other.isPrivate == this.isPrivate &&
          other.lastPlayedPositionMs == this.lastPlayedPositionMs &&
          other.lastPlayedAtMs == this.lastPlayedAtMs);
}

class VideoIndexEntriesCompanion extends UpdateCompanion<VideoIndexEntry> {
  final Value<String> id;
  final Value<int> mediaStoreId;
  final Value<String> uri;
  final Value<String> displayName;
  final Value<String> folderId;
  final Value<String> folderName;
  final Value<String?> relativePath;
  final Value<String?> mimeType;
  final Value<int?> durationMs;
  final Value<int?> sizeBytes;
  final Value<int?> width;
  final Value<int?> height;
  final Value<int?> rotationDegrees;
  final Value<int?> bitrate;
  final Value<double?> frameRate;
  final Value<String?> subtitleUri;
  final Value<int?> createdAtMs;
  final Value<int?> modifiedAtMs;
  final Value<bool> isHdr;
  final Value<bool> is360Video;
  final Value<bool> isSlowMotion;
  final Value<bool> isHyperlapse;
  final Value<bool> isDrm;
  final Value<bool> isPlayable;
  final Value<bool> isFavorite;
  final Value<bool> isPrivate;
  final Value<int?> lastPlayedPositionMs;
  final Value<int?> lastPlayedAtMs;
  final Value<int> rowid;
  const VideoIndexEntriesCompanion({
    this.id = const Value.absent(),
    this.mediaStoreId = const Value.absent(),
    this.uri = const Value.absent(),
    this.displayName = const Value.absent(),
    this.folderId = const Value.absent(),
    this.folderName = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.subtitleUri = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.modifiedAtMs = const Value.absent(),
    this.isHdr = const Value.absent(),
    this.is360Video = const Value.absent(),
    this.isSlowMotion = const Value.absent(),
    this.isHyperlapse = const Value.absent(),
    this.isDrm = const Value.absent(),
    this.isPlayable = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.lastPlayedPositionMs = const Value.absent(),
    this.lastPlayedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideoIndexEntriesCompanion.insert({
    required String id,
    required int mediaStoreId,
    required String uri,
    required String displayName,
    required String folderId,
    required String folderName,
    this.relativePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotationDegrees = const Value.absent(),
    this.bitrate = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.subtitleUri = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.modifiedAtMs = const Value.absent(),
    this.isHdr = const Value.absent(),
    this.is360Video = const Value.absent(),
    this.isSlowMotion = const Value.absent(),
    this.isHyperlapse = const Value.absent(),
    this.isDrm = const Value.absent(),
    this.isPlayable = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPrivate = const Value.absent(),
    this.lastPlayedPositionMs = const Value.absent(),
    this.lastPlayedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        mediaStoreId = Value(mediaStoreId),
        uri = Value(uri),
        displayName = Value(displayName),
        folderId = Value(folderId),
        folderName = Value(folderName);
  static Insertable<VideoIndexEntry> custom({
    Expression<String>? id,
    Expression<int>? mediaStoreId,
    Expression<String>? uri,
    Expression<String>? displayName,
    Expression<String>? folderId,
    Expression<String>? folderName,
    Expression<String>? relativePath,
    Expression<String>? mimeType,
    Expression<int>? durationMs,
    Expression<int>? sizeBytes,
    Expression<int>? width,
    Expression<int>? height,
    Expression<int>? rotationDegrees,
    Expression<int>? bitrate,
    Expression<double>? frameRate,
    Expression<String>? subtitleUri,
    Expression<int>? createdAtMs,
    Expression<int>? modifiedAtMs,
    Expression<bool>? isHdr,
    Expression<bool>? is360Video,
    Expression<bool>? isSlowMotion,
    Expression<bool>? isHyperlapse,
    Expression<bool>? isDrm,
    Expression<bool>? isPlayable,
    Expression<bool>? isFavorite,
    Expression<bool>? isPrivate,
    Expression<int>? lastPlayedPositionMs,
    Expression<int>? lastPlayedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaStoreId != null) 'media_store_id': mediaStoreId,
      if (uri != null) 'uri': uri,
      if (displayName != null) 'display_name': displayName,
      if (folderId != null) 'folder_id': folderId,
      if (folderName != null) 'folder_name': folderName,
      if (relativePath != null) 'relative_path': relativePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (durationMs != null) 'duration_ms': durationMs,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotationDegrees != null) 'rotation_degrees': rotationDegrees,
      if (bitrate != null) 'bitrate': bitrate,
      if (frameRate != null) 'frame_rate': frameRate,
      if (subtitleUri != null) 'subtitle_uri': subtitleUri,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (modifiedAtMs != null) 'modified_at_ms': modifiedAtMs,
      if (isHdr != null) 'is_hdr': isHdr,
      if (is360Video != null) 'is360_video': is360Video,
      if (isSlowMotion != null) 'is_slow_motion': isSlowMotion,
      if (isHyperlapse != null) 'is_hyperlapse': isHyperlapse,
      if (isDrm != null) 'is_drm': isDrm,
      if (isPlayable != null) 'is_playable': isPlayable,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isPrivate != null) 'is_private': isPrivate,
      if (lastPlayedPositionMs != null)
        'last_played_position_ms': lastPlayedPositionMs,
      if (lastPlayedAtMs != null) 'last_played_at_ms': lastPlayedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideoIndexEntriesCompanion copyWith(
      {Value<String>? id,
      Value<int>? mediaStoreId,
      Value<String>? uri,
      Value<String>? displayName,
      Value<String>? folderId,
      Value<String>? folderName,
      Value<String?>? relativePath,
      Value<String?>? mimeType,
      Value<int?>? durationMs,
      Value<int?>? sizeBytes,
      Value<int?>? width,
      Value<int?>? height,
      Value<int?>? rotationDegrees,
      Value<int?>? bitrate,
      Value<double?>? frameRate,
      Value<String?>? subtitleUri,
      Value<int?>? createdAtMs,
      Value<int?>? modifiedAtMs,
      Value<bool>? isHdr,
      Value<bool>? is360Video,
      Value<bool>? isSlowMotion,
      Value<bool>? isHyperlapse,
      Value<bool>? isDrm,
      Value<bool>? isPlayable,
      Value<bool>? isFavorite,
      Value<bool>? isPrivate,
      Value<int?>? lastPlayedPositionMs,
      Value<int?>? lastPlayedAtMs,
      Value<int>? rowid}) {
    return VideoIndexEntriesCompanion(
      id: id ?? this.id,
      mediaStoreId: mediaStoreId ?? this.mediaStoreId,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      folderId: folderId ?? this.folderId,
      folderName: folderName ?? this.folderName,
      relativePath: relativePath ?? this.relativePath,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      width: width ?? this.width,
      height: height ?? this.height,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      bitrate: bitrate ?? this.bitrate,
      frameRate: frameRate ?? this.frameRate,
      subtitleUri: subtitleUri ?? this.subtitleUri,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      modifiedAtMs: modifiedAtMs ?? this.modifiedAtMs,
      isHdr: isHdr ?? this.isHdr,
      is360Video: is360Video ?? this.is360Video,
      isSlowMotion: isSlowMotion ?? this.isSlowMotion,
      isHyperlapse: isHyperlapse ?? this.isHyperlapse,
      isDrm: isDrm ?? this.isDrm,
      isPlayable: isPlayable ?? this.isPlayable,
      isFavorite: isFavorite ?? this.isFavorite,
      isPrivate: isPrivate ?? this.isPrivate,
      lastPlayedPositionMs: lastPlayedPositionMs ?? this.lastPlayedPositionMs,
      lastPlayedAtMs: lastPlayedAtMs ?? this.lastPlayedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaStoreId.present) {
      map['media_store_id'] = Variable<int>(mediaStoreId.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (folderName.present) {
      map['folder_name'] = Variable<String>(folderName.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (rotationDegrees.present) {
      map['rotation_degrees'] = Variable<int>(rotationDegrees.value);
    }
    if (bitrate.present) {
      map['bitrate'] = Variable<int>(bitrate.value);
    }
    if (frameRate.present) {
      map['frame_rate'] = Variable<double>(frameRate.value);
    }
    if (subtitleUri.present) {
      map['subtitle_uri'] = Variable<String>(subtitleUri.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (modifiedAtMs.present) {
      map['modified_at_ms'] = Variable<int>(modifiedAtMs.value);
    }
    if (isHdr.present) {
      map['is_hdr'] = Variable<bool>(isHdr.value);
    }
    if (is360Video.present) {
      map['is360_video'] = Variable<bool>(is360Video.value);
    }
    if (isSlowMotion.present) {
      map['is_slow_motion'] = Variable<bool>(isSlowMotion.value);
    }
    if (isHyperlapse.present) {
      map['is_hyperlapse'] = Variable<bool>(isHyperlapse.value);
    }
    if (isDrm.present) {
      map['is_drm'] = Variable<bool>(isDrm.value);
    }
    if (isPlayable.present) {
      map['is_playable'] = Variable<bool>(isPlayable.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isPrivate.present) {
      map['is_private'] = Variable<bool>(isPrivate.value);
    }
    if (lastPlayedPositionMs.present) {
      map['last_played_position_ms'] =
          Variable<int>(lastPlayedPositionMs.value);
    }
    if (lastPlayedAtMs.present) {
      map['last_played_at_ms'] = Variable<int>(lastPlayedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoIndexEntriesCompanion(')
          ..write('id: $id, ')
          ..write('mediaStoreId: $mediaStoreId, ')
          ..write('uri: $uri, ')
          ..write('displayName: $displayName, ')
          ..write('folderId: $folderId, ')
          ..write('folderName: $folderName, ')
          ..write('relativePath: $relativePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotationDegrees: $rotationDegrees, ')
          ..write('bitrate: $bitrate, ')
          ..write('frameRate: $frameRate, ')
          ..write('subtitleUri: $subtitleUri, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('modifiedAtMs: $modifiedAtMs, ')
          ..write('isHdr: $isHdr, ')
          ..write('is360Video: $is360Video, ')
          ..write('isSlowMotion: $isSlowMotion, ')
          ..write('isHyperlapse: $isHyperlapse, ')
          ..write('isDrm: $isDrm, ')
          ..write('isPlayable: $isPlayable, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPrivate: $isPrivate, ')
          ..write('lastPlayedPositionMs: $lastPlayedPositionMs, ')
          ..write('lastPlayedAtMs: $lastPlayedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VideoIndexEntriesTable videoIndexEntries =
      $VideoIndexEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [videoIndexEntries];
}

typedef $$VideoIndexEntriesTableCreateCompanionBuilder
    = VideoIndexEntriesCompanion Function({
  required String id,
  required int mediaStoreId,
  required String uri,
  required String displayName,
  required String folderId,
  required String folderName,
  Value<String?> relativePath,
  Value<String?> mimeType,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<int?> width,
  Value<int?> height,
  Value<int?> rotationDegrees,
  Value<int?> bitrate,
  Value<double?> frameRate,
  Value<String?> subtitleUri,
  Value<int?> createdAtMs,
  Value<int?> modifiedAtMs,
  Value<bool> isHdr,
  Value<bool> is360Video,
  Value<bool> isSlowMotion,
  Value<bool> isHyperlapse,
  Value<bool> isDrm,
  Value<bool> isPlayable,
  Value<bool> isFavorite,
  Value<bool> isPrivate,
  Value<int?> lastPlayedPositionMs,
  Value<int?> lastPlayedAtMs,
  Value<int> rowid,
});
typedef $$VideoIndexEntriesTableUpdateCompanionBuilder
    = VideoIndexEntriesCompanion Function({
  Value<String> id,
  Value<int> mediaStoreId,
  Value<String> uri,
  Value<String> displayName,
  Value<String> folderId,
  Value<String> folderName,
  Value<String?> relativePath,
  Value<String?> mimeType,
  Value<int?> durationMs,
  Value<int?> sizeBytes,
  Value<int?> width,
  Value<int?> height,
  Value<int?> rotationDegrees,
  Value<int?> bitrate,
  Value<double?> frameRate,
  Value<String?> subtitleUri,
  Value<int?> createdAtMs,
  Value<int?> modifiedAtMs,
  Value<bool> isHdr,
  Value<bool> is360Video,
  Value<bool> isSlowMotion,
  Value<bool> isHyperlapse,
  Value<bool> isDrm,
  Value<bool> isPlayable,
  Value<bool> isFavorite,
  Value<bool> isPrivate,
  Value<int?> lastPlayedPositionMs,
  Value<int?> lastPlayedAtMs,
  Value<int> rowid,
});

class $$VideoIndexEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VideoIndexEntriesTable> {
  $$VideoIndexEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bitrate => $composableBuilder(
      column: $table.bitrate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get frameRate => $composableBuilder(
      column: $table.frameRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtitleUri => $composableBuilder(
      column: $table.subtitleUri, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get modifiedAtMs => $composableBuilder(
      column: $table.modifiedAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHdr => $composableBuilder(
      column: $table.isHdr, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get is360Video => $composableBuilder(
      column: $table.is360Video, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSlowMotion => $composableBuilder(
      column: $table.isSlowMotion, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isHyperlapse => $composableBuilder(
      column: $table.isHyperlapse, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDrm => $composableBuilder(
      column: $table.isDrm, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPlayable => $composableBuilder(
      column: $table.isPlayable, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPlayedPositionMs => $composableBuilder(
      column: $table.lastPlayedPositionMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastPlayedAtMs => $composableBuilder(
      column: $table.lastPlayedAtMs,
      builder: (column) => ColumnFilters(column));
}

class $$VideoIndexEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoIndexEntriesTable> {
  $$VideoIndexEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uri => $composableBuilder(
      column: $table.uri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderId => $composableBuilder(
      column: $table.folderId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bitrate => $composableBuilder(
      column: $table.bitrate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get frameRate => $composableBuilder(
      column: $table.frameRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtitleUri => $composableBuilder(
      column: $table.subtitleUri, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get modifiedAtMs => $composableBuilder(
      column: $table.modifiedAtMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHdr => $composableBuilder(
      column: $table.isHdr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get is360Video => $composableBuilder(
      column: $table.is360Video, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSlowMotion => $composableBuilder(
      column: $table.isSlowMotion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isHyperlapse => $composableBuilder(
      column: $table.isHyperlapse,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDrm => $composableBuilder(
      column: $table.isDrm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPlayable => $composableBuilder(
      column: $table.isPlayable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrivate => $composableBuilder(
      column: $table.isPrivate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPlayedPositionMs => $composableBuilder(
      column: $table.lastPlayedPositionMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastPlayedAtMs => $composableBuilder(
      column: $table.lastPlayedAtMs,
      builder: (column) => ColumnOrderings(column));
}

class $$VideoIndexEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoIndexEntriesTable> {
  $$VideoIndexEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get mediaStoreId => $composableBuilder(
      column: $table.mediaStoreId, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<String> get folderName => $composableBuilder(
      column: $table.folderName, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<int> get rotationDegrees => $composableBuilder(
      column: $table.rotationDegrees, builder: (column) => column);

  GeneratedColumn<int> get bitrate =>
      $composableBuilder(column: $table.bitrate, builder: (column) => column);

  GeneratedColumn<double> get frameRate =>
      $composableBuilder(column: $table.frameRate, builder: (column) => column);

  GeneratedColumn<String> get subtitleUri => $composableBuilder(
      column: $table.subtitleUri, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => column);

  GeneratedColumn<int> get modifiedAtMs => $composableBuilder(
      column: $table.modifiedAtMs, builder: (column) => column);

  GeneratedColumn<bool> get isHdr =>
      $composableBuilder(column: $table.isHdr, builder: (column) => column);

  GeneratedColumn<bool> get is360Video => $composableBuilder(
      column: $table.is360Video, builder: (column) => column);

  GeneratedColumn<bool> get isSlowMotion => $composableBuilder(
      column: $table.isSlowMotion, builder: (column) => column);

  GeneratedColumn<bool> get isHyperlapse => $composableBuilder(
      column: $table.isHyperlapse, builder: (column) => column);

  GeneratedColumn<bool> get isDrm =>
      $composableBuilder(column: $table.isDrm, builder: (column) => column);

  GeneratedColumn<bool> get isPlayable => $composableBuilder(
      column: $table.isPlayable, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
      column: $table.isFavorite, builder: (column) => column);

  GeneratedColumn<bool> get isPrivate =>
      $composableBuilder(column: $table.isPrivate, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedPositionMs => $composableBuilder(
      column: $table.lastPlayedPositionMs, builder: (column) => column);

  GeneratedColumn<int> get lastPlayedAtMs => $composableBuilder(
      column: $table.lastPlayedAtMs, builder: (column) => column);
}

class $$VideoIndexEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VideoIndexEntriesTable,
    VideoIndexEntry,
    $$VideoIndexEntriesTableFilterComposer,
    $$VideoIndexEntriesTableOrderingComposer,
    $$VideoIndexEntriesTableAnnotationComposer,
    $$VideoIndexEntriesTableCreateCompanionBuilder,
    $$VideoIndexEntriesTableUpdateCompanionBuilder,
    (
      VideoIndexEntry,
      BaseReferences<_$AppDatabase, $VideoIndexEntriesTable, VideoIndexEntry>
    ),
    VideoIndexEntry,
    PrefetchHooks Function()> {
  $$VideoIndexEntriesTableTableManager(
      _$AppDatabase db, $VideoIndexEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoIndexEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoIndexEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoIndexEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> mediaStoreId = const Value.absent(),
            Value<String> uri = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> folderId = const Value.absent(),
            Value<String> folderName = const Value.absent(),
            Value<String?> relativePath = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> rotationDegrees = const Value.absent(),
            Value<int?> bitrate = const Value.absent(),
            Value<double?> frameRate = const Value.absent(),
            Value<String?> subtitleUri = const Value.absent(),
            Value<int?> createdAtMs = const Value.absent(),
            Value<int?> modifiedAtMs = const Value.absent(),
            Value<bool> isHdr = const Value.absent(),
            Value<bool> is360Video = const Value.absent(),
            Value<bool> isSlowMotion = const Value.absent(),
            Value<bool> isHyperlapse = const Value.absent(),
            Value<bool> isDrm = const Value.absent(),
            Value<bool> isPlayable = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isPrivate = const Value.absent(),
            Value<int?> lastPlayedPositionMs = const Value.absent(),
            Value<int?> lastPlayedAtMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideoIndexEntriesCompanion(
            id: id,
            mediaStoreId: mediaStoreId,
            uri: uri,
            displayName: displayName,
            folderId: folderId,
            folderName: folderName,
            relativePath: relativePath,
            mimeType: mimeType,
            durationMs: durationMs,
            sizeBytes: sizeBytes,
            width: width,
            height: height,
            rotationDegrees: rotationDegrees,
            bitrate: bitrate,
            frameRate: frameRate,
            subtitleUri: subtitleUri,
            createdAtMs: createdAtMs,
            modifiedAtMs: modifiedAtMs,
            isHdr: isHdr,
            is360Video: is360Video,
            isSlowMotion: isSlowMotion,
            isHyperlapse: isHyperlapse,
            isDrm: isDrm,
            isPlayable: isPlayable,
            isFavorite: isFavorite,
            isPrivate: isPrivate,
            lastPlayedPositionMs: lastPlayedPositionMs,
            lastPlayedAtMs: lastPlayedAtMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int mediaStoreId,
            required String uri,
            required String displayName,
            required String folderId,
            required String folderName,
            Value<String?> relativePath = const Value.absent(),
            Value<String?> mimeType = const Value.absent(),
            Value<int?> durationMs = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<int?> rotationDegrees = const Value.absent(),
            Value<int?> bitrate = const Value.absent(),
            Value<double?> frameRate = const Value.absent(),
            Value<String?> subtitleUri = const Value.absent(),
            Value<int?> createdAtMs = const Value.absent(),
            Value<int?> modifiedAtMs = const Value.absent(),
            Value<bool> isHdr = const Value.absent(),
            Value<bool> is360Video = const Value.absent(),
            Value<bool> isSlowMotion = const Value.absent(),
            Value<bool> isHyperlapse = const Value.absent(),
            Value<bool> isDrm = const Value.absent(),
            Value<bool> isPlayable = const Value.absent(),
            Value<bool> isFavorite = const Value.absent(),
            Value<bool> isPrivate = const Value.absent(),
            Value<int?> lastPlayedPositionMs = const Value.absent(),
            Value<int?> lastPlayedAtMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VideoIndexEntriesCompanion.insert(
            id: id,
            mediaStoreId: mediaStoreId,
            uri: uri,
            displayName: displayName,
            folderId: folderId,
            folderName: folderName,
            relativePath: relativePath,
            mimeType: mimeType,
            durationMs: durationMs,
            sizeBytes: sizeBytes,
            width: width,
            height: height,
            rotationDegrees: rotationDegrees,
            bitrate: bitrate,
            frameRate: frameRate,
            subtitleUri: subtitleUri,
            createdAtMs: createdAtMs,
            modifiedAtMs: modifiedAtMs,
            isHdr: isHdr,
            is360Video: is360Video,
            isSlowMotion: isSlowMotion,
            isHyperlapse: isHyperlapse,
            isDrm: isDrm,
            isPlayable: isPlayable,
            isFavorite: isFavorite,
            isPrivate: isPrivate,
            lastPlayedPositionMs: lastPlayedPositionMs,
            lastPlayedAtMs: lastPlayedAtMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VideoIndexEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VideoIndexEntriesTable,
    VideoIndexEntry,
    $$VideoIndexEntriesTableFilterComposer,
    $$VideoIndexEntriesTableOrderingComposer,
    $$VideoIndexEntriesTableAnnotationComposer,
    $$VideoIndexEntriesTableCreateCompanionBuilder,
    $$VideoIndexEntriesTableUpdateCompanionBuilder,
    (
      VideoIndexEntry,
      BaseReferences<_$AppDatabase, $VideoIndexEntriesTable, VideoIndexEntry>
    ),
    VideoIndexEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VideoIndexEntriesTableTableManager get videoIndexEntries =>
      $$VideoIndexEntriesTableTableManager(_db, _db.videoIndexEntries);
}
