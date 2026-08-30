import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('settings screen only shows spec-defined sections',
      (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
            ),
            child: child!,
          );
        },
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('ビデオ'), findsOneWidget);
    expect(find.text('バージョン 1.0.0'), findsOneWidget);
    expect(find.text('最新バージョンがインストールされています。'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('オープンソースライセンス'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('利用規約'), findsOneWidget);
    expect(find.text('オープンソースライセンス'), findsOneWidget);

    expect(find.text('再生・表示'), findsNothing);
    expect(find.text('権限'), findsNothing);
    expect(find.text('表示'), findsNothing);
    expect(find.text('ストレージ'), findsNothing);
    expect(find.text('プライベートPIN'), findsNothing);
    expect(find.text('プライベートロック方式'), findsNothing);
    expect(find.text('サムネイルキャッシュ上限'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
