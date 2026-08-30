import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/shared/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clearVideoIndexEntries removes cached index rows', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    await database.replaceVideoIndexEntries([
      VideoIndexEntriesCompanion.insert(
        id: '1',
        mediaStoreId: 1,
        uri: 'content://media/external/video/media/1',
        displayName: 'sample.mp4',
        folderId: 'camera',
        folderName: 'Camera',
        relativePath: const Value('DCIM/Camera/'),
      ),
    ]);

    expect(await database.getVideoIndexEntries(), hasLength(1));

    await database.clearVideoIndexEntries();

    expect(await database.getVideoIndexEntries(), isEmpty);
  });

  test('schema v3 stores extracted codec metadata', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    expect(database.schemaVersion, 3);
    await database.replaceVideoIndexEntries([
      VideoIndexEntriesCompanion.insert(
        id: 'codec',
        mediaStoreId: 2,
        uri: 'content://media/external/video/media/2',
        displayName: 'codec.mp4',
        folderId: 'camera',
        folderName: 'Camera',
        videoCodec: const Value('video/avc'),
        audioCodec: const Value('audio/mp4a-latm'),
        audioChannelCount: const Value(2),
      ),
    ]);

    final row = (await database.getVideoIndexEntries()).single;
    expect(row.videoCodec, 'video/avc');
    expect(row.audioCodec, 'audio/mp4a-latm');
    expect(row.audioChannelCount, 2);
  });
}
