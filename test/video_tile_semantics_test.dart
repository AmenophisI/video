import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/video/domain/video.dart';
import 'package:video_player/src/modules/video/presentation/widgets/playback_progress_bar.dart';
import 'package:video_player/src/modules/video/presentation/widgets/video_tile.dart';

void main() {
  testWidgets('video tile exposes title duration selection and progress',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 300,
              child: VideoTile(
                video: Video(
                  id: 'video-001',
                  mediaStoreId: 1,
                  uri: Uri.parse('content://media/external/video/media/1'),
                  displayName: '家族旅行.mp4',
                  folderId: 'camera',
                  folderName: 'Camera',
                  duration: const Duration(minutes: 4, seconds: 32),
                  sizeBytes: 164000000,
                  lastPlayedPosition: const Duration(minutes: 1, seconds: 12),
                ),
                showPlaybackProgress: true,
                showTags: true,
                selected: true,
                onTap: () {},
                onLongPress: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp('家族旅行.mp4'),
        ),
        findsWidgets,
      );
      expect(find.bySemanticsLabel(RegExp('再生時間 4:32')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('選択中')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('視聴進捗 26パーセント')), findsWidgets);
      expect(find.byType(PlaybackProgressBar), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('video tile fits compact grid cards with metadata',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 188,
            height: 276,
            child: VideoTile(
              video: Video(
                id: 'video-qa',
                mediaStoreId: 100,
                uri: Uri.parse('content://media/external/video/media/100'),
                displayName: 'codex_video_library_qa.mp4',
                folderId: 'downloads',
                folderName: 'Download',
                duration: const Duration(seconds: 1),
                sizeBytes: 49962,
                modifiedAt: DateTime(2026, 6, 14),
              ),
              showPlaybackProgress: true,
              showTags: true,
              onTap: () {},
              onLongPress: () {},
              onPreview: () {},
              onDetails: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('codex_video_library_qa.mp4'), findsOneWidget);
    expect(find.textContaining('更新 2026/06/14'), findsOneWidget);
  });
}
