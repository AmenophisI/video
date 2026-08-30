import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';
import 'package:video_player/src/modules/video/domain/video.dart';
import 'package:video_player/src/modules/video/presentation/video_detail_screen.dart';

void main() {
  testWidgets('video detail screen handles long metadata on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryVideoRepository(
      seedVideos: [
        Video(
          id: 'long-detail',
          mediaStoreId: 100,
          uri: Uri.parse(
            'content://media/external/video/media/'
            'very-long-video-content-uri-that-should-not-overflow-the-screen',
          ),
          displayName: 'とても長い名前の動画ファイルで詳細画面の表示崩れを確認するためのサンプル.mp4',
          folderId: 'long-folder',
          folderName: 'Very Long Folder Name',
          relativePath:
              'Movies/VeryLongFolderName/AnotherLongNestedFolderName/',
          mimeType: 'video/mp4',
          duration: const Duration(hours: 1, minutes: 12, seconds: 34),
          sizeBytes: 1024 * 1024 * 800,
          width: 3840,
          height: 2160,
          frameRate: 120,
          isHdr: true,
          videoCodec: 'video/avc',
          audioCodec: 'audio/mp4a-latm',
          audioChannelCount: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child!,
            );
          },
          home: const VideoDetailScreen(videoId: 'long-detail'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('詳細'), findsOneWidget);
    final scrollable = find.byType(Scrollable).first;
    for (final label in [
      '日時',
      '名前',
      'サイズ',
      '他のデバイスに転送',
      '保存場所',
      '位置情報',
      '動画',
      '音声',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: scrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.textContaining('stereo / AAC'),
      260,
      scrollable: scrollable,
    );
    expect(find.textContaining('H.264'), findsOneWidget);
    expect(find.textContaining('stereo / AAC'), findsOneWidget);
    expect(find.text('場所コピー'), findsNothing);
    expect(find.text('名前変更'), findsNothing);
    expect(find.text('削除'), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown detail metadata is displayed without guessing',
      (tester) async {
    final repository = InMemoryVideoRepository(
      seedVideos: [
        Video(
          id: 'unknown-detail',
          mediaStoreId: 101,
          uri: Uri.parse('content://media/external/video/media/101'),
          displayName: 'sample',
          folderId: '',
          folderName: '',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [videoRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: VideoDetailScreen(videoId: 'unknown-detail'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('--'), findsWidgets);
    expect(find.text('場所コピー'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
