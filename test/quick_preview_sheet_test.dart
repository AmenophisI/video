import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/playback/presentation/quick_preview_sheet.dart';
import 'package:video_player/src/modules/video/domain/video.dart';

void main() {
  testWidgets('shows an error for unplayable videos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuickPreviewSheet(
              video: Video(
                id: 'unplayable',
                mediaStoreId: 1,
                uri: Uri.parse('content://media/external/video/media/1'),
                displayName: 'broken.mp4',
                folderId: 'download',
                folderName: 'Download',
                isPlayable: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('この動画はアプリ内で再生できません'), findsOneWidget);
    expect(find.text('broken.mp4'), findsOneWidget);
    expect(find.byType(AndroidView), findsNothing);
  });

  testWidgets('shows DRM reason for protected unplayable videos',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: QuickPreviewSheet(
              video: Video(
                id: 'drm-unplayable',
                mediaStoreId: 3,
                uri: Uri.parse('content://media/external/video/media/3'),
                displayName: 'protected.mp4',
                folderId: 'download',
                folderName: 'Download',
                isDrm: true,
                isPlayable: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('この動画はアプリ内で再生できません'), findsOneWidget);
    expect(find.textContaining('DRM保護'), findsOneWidget);
  });

  testWidgets('preview sheet scrolls on small screens with large text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.8),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: QuickPreviewSheet(
              video: Video(
                id: 'unplayable-small',
                mediaStoreId: 2,
                uri: Uri.parse('content://media/external/video/media/2'),
                displayName: 'とても長い名前の壊れた動画ファイル.mp4',
                folderId: 'download',
                folderName: 'Download',
                isPlayable: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('この動画はアプリ内で再生できません'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
