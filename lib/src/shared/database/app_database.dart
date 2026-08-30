import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class VideoIndexEntries extends Table {
  TextColumn get id => text()();
  IntColumn get mediaStoreId => integer()();
  TextColumn get uri => text()();
  TextColumn get displayName => text()();
  TextColumn get folderId => text()();
  TextColumn get folderName => text()();
  TextColumn get relativePath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get durationMs => integer().nullable()();
  IntColumn get sizeBytes => integer().nullable()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get rotationDegrees => integer().nullable()();
  IntColumn get bitrate => integer().nullable()();
  RealColumn get frameRate => real().nullable()();
  TextColumn get videoCodec => text().nullable()();
  TextColumn get audioCodec => text().nullable()();
  IntColumn get audioChannelCount => integer().nullable()();
  TextColumn get subtitleUri => text().nullable()();
  IntColumn get createdAtMs => integer().nullable()();
  IntColumn get modifiedAtMs => integer().nullable()();
  BoolColumn get isHdr => boolean().withDefault(const Constant(false))();
  BoolColumn get is360Video => boolean().withDefault(const Constant(false))();
  BoolColumn get isSlowMotion => boolean().withDefault(const Constant(false))();
  BoolColumn get isHyperlapse => boolean().withDefault(const Constant(false))();
  BoolColumn get isDrm => boolean().withDefault(const Constant(false))();
  BoolColumn get isPlayable => boolean().withDefault(const Constant(true))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  IntColumn get lastPlayedPositionMs => integer().nullable()();
  IntColumn get lastPlayedAtMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [VideoIndexEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(
            videoIndexEntries,
            videoIndexEntries.isHyperlapse,
          );
        }
        if (from < 3) {
          await migrator.addColumn(
            videoIndexEntries,
            videoIndexEntries.videoCodec,
          );
          await migrator.addColumn(
            videoIndexEntries,
            videoIndexEntries.audioCodec,
          );
          await migrator.addColumn(
            videoIndexEntries,
            videoIndexEntries.audioChannelCount,
          );
        }
      },
    );
  }

  Stream<List<VideoIndexEntry>> watchVideoIndexEntries() {
    return select(videoIndexEntries).watch();
  }

  Future<List<VideoIndexEntry>> getVideoIndexEntries() {
    return select(videoIndexEntries).get();
  }

  Future<void> replaceVideoIndexEntries(
    List<VideoIndexEntriesCompanion> entries,
  ) async {
    await transaction(() async {
      await delete(videoIndexEntries).go();
      await batch((batch) {
        batch.insertAll(videoIndexEntries, entries);
      });
    });
  }

  Future<void> clearVideoIndexEntries() async {
    await delete(videoIndexEntries).go();
  }

  Future<void> updateVideoIndexEntry(VideoIndexEntriesCompanion entry) async {
    await into(videoIndexEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteVideoIndexEntry(String id) async {
    await (delete(videoIndexEntries)..where((entry) => entry.id.equals(id)))
        .go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'video_library.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
