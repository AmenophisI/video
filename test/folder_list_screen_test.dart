import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/folder/presentation/folder_list_screen.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';

void main() {
  testWidgets('folder list exposes accessible folder rows', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            videoRepositoryProvider.overrideWithValue(
              InMemoryVideoRepository.seeded(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: FolderListScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
      expect(find.bySemanticsLabel('Camera フォルダ、動画3件'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('folder creation uses the folder path picker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FolderListScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('フォルダ作成'));
    await tester.pumpAndSettle();

    expect(find.text('フォルダ作成'), findsWidgets);
    expect(find.text('作成するフォルダ'), findsOneWidget);
    expect(find.text('既存フォルダ'), findsOneWidget);
    expect(find.text('Movies/NewFolder'), findsWidgets);
    expect(find.text('Download'), findsWidgets);
  });

  testWidgets('folder creation maps platform errors to readable messages',
      (tester) async {
    const channel = MethodChannel('video_player/media_store');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'createFolder') {
        throw PlatformException(
          code: 'folder_already_exists',
          message: 'Folder already exists.',
        );
      }

      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FolderListScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('フォルダ作成'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('作成'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('同名のフォルダが既にあります'), findsOneWidget);
  });

  testWidgets('folder rename uses the folder path picker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          videoRepositoryProvider.overrideWithValue(
            InMemoryVideoRepository.seeded(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: FolderListScreen()),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('folder-actions-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('フォルダ名変更'));
    await tester.pumpAndSettle();

    expect(find.text('フォルダ名変更'), findsWidgets);
    expect(find.text('変更後のフォルダ'), findsOneWidget);
    expect(find.text('既存フォルダ'), findsOneWidget);
    expect(find.text('Movies/Camera'), findsWidgets);
  });
}
