import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/modules/playback/presentation/player_settings_screen.dart';
import 'package:video_player/src/modules/settings/application/settings_providers.dart';
import 'package:video_player/src/modules/settings/domain/app_settings.dart';
import 'package:video_player/src/modules/settings/domain/settings_repository.dart';

void main() {
  testWidgets('Samsung player settings uses one card with seven rows',
      (tester) async {
    final repository = _TestSettingsRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: PlayerSettingsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('動画プレーヤー設定'), findsOneWidget);
    for (final label in [
      '動画を自動連続再生',
      '動画を自動リピート再生',
      'バックグラウンド再生',
      '速度コントローラーを表示',
      '動画の明るさ',
      '動画プレーヤーについて',
      'お問い合わせ',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(SwitchListTile), findsNWidgets(4));
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches.map((widget) => widget.value), [false, false, false, true]);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('動画を自動連続再生'));
    await tester.pump();
    expect(repository.current.autoPlayNext, isTrue);
  });
}

class _TestSettingsRepository implements SettingsRepository {
  final _controller = StreamController<AppSettings>.broadcast();
  AppSettings current = const AppSettings();

  @override
  Stream<AppSettings> watchSettings() async* {
    yield current;
    yield* _controller.stream;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    current = settings;
    _controller.add(settings);
  }

  void dispose() => _controller.close();
}
