import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:video_player/src/modules/folder/presentation/folder_list_screen.dart';
import 'package:video_player/src/modules/video/application/video_providers.dart';
import 'package:video_player/src/modules/video/data/repositories/in_memory_video_repository.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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

  testWidgets('folder creation uses the Samsung name dialog', (tester) async {
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

    await tester.tap(find.byTooltip('その他'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('フォルダを作成'));
    await tester.pumpAndSettle();

    expect(find.text('フォルダを作成'), findsWidgets);
    expect(find.text('フォルダ名'), findsOneWidget);
    expect(find.text('フォルダ1'), findsOneWidget);
    expect(find.text('キャンセル'), findsOneWidget);
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

    await tester.tap(find.byTooltip('その他'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('フォルダを作成'));
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
