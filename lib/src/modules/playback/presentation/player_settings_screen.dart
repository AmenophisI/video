import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../media_access/data/app_info/app_info_adapter.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../data/player_system_adapter.dart';

class PlayerSettingsScreen extends ConsumerWidget {
  const PlayerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 88,
          leading: const BackButton(),
          titleSpacing: 0,
          title: const Text(
            '動画プレーヤー設定',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
        ),
        body: settingsAsync.when(
          data: (settings) => ListView(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 36),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: ColoredBox(
                  color: const Color(0xFF1C1C1D),
                  child: Column(
                    children: [
                      _SettingsSwitchRow(
                        label: '動画を自動連続再生',
                        value: settings.autoPlayNext,
                        onChanged: (value) => _update(
                          ref,
                          settings.copyWith(autoPlayNext: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        label: '動画を自動リピート再生',
                        value: settings.autoRepeat,
                        onChanged: (value) => _update(
                          ref,
                          settings.copyWith(autoRepeat: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        label: 'バックグラウンド再生',
                        value: settings.backgroundPlayback,
                        onChanged: (value) => _update(
                          ref,
                          settings.copyWith(backgroundPlayback: value),
                        ),
                      ),
                      _SettingsSwitchRow(
                        label: '速度コントローラーを表示',
                        value: settings.showSpeedController,
                        onChanged: (value) => _update(
                          ref,
                          settings.copyWith(showSpeedController: value),
                        ),
                      ),
                      _SettingsActionRow(
                        label: '動画の明るさ',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _VideoBrightnessScreen(),
                          ),
                        ),
                      ),
                      _SettingsActionRow(
                        label: '動画プレーヤーについて',
                        onTap: () => unawaited(_showAbout(context)),
                      ),
                      _SettingsActionRow(
                        label: 'お問い合わせ',
                        showDivider: false,
                        onTap: () => _showContact(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  void _update(WidgetRef ref, AppSettings settings) {
    unawaited(ref.read(updateSettingsUseCaseProvider).call(settings));
  }

  void _showContact(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('お問い合わせ'),
        content: const Text(
          'アプリに関するお問い合わせは、配布元のサポート窓口をご利用ください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) async {
    final appInfo = await const AppInfoAdapter().getAppInfo();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画プレーヤーについて'),
        content: Text(
          '${appInfo.appName}\nバージョン ${appInfo.versionLabel}\n\n端末内の動画を再生するローカル動画プレーヤーです。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 76,
          child: SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
            ),
            value: value,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF1688F8),
            inactiveThumbColor: const Color(0xFFF4F4F4),
            inactiveTrackColor: const Color(0xFF666667),
            onChanged: onChanged,
          ),
        ),
        const Divider(height: 1, indent: 20, endIndent: 20),
      ],
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 76,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(label, style: const TextStyle(fontSize: 17)),
            onTap: onTap,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 20, endIndent: 20),
      ],
    );
  }
}

class _VideoBrightnessScreen extends ConsumerWidget {
  const _VideoBrightnessScreen();

  static const PlayerSystemAdapter _systemAdapter = PlayerSystemAdapter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? const AppSettings();
    return Scaffold(
      appBar: AppBar(title: const Text('動画の明るさ')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.brightness_6_outlined, size: 48),
            const SizedBox(height: 20),
            Slider(
              value: settings.videoBrightness.clamp(0.01, 1),
              min: 0.01,
              max: 1,
              divisions: 20,
              label: '${(settings.videoBrightness * 100).round()}%',
              onChanged: (value) {
                unawaited(_systemAdapter.setScreenBrightness(value));
                unawaited(
                  ref.read(updateSettingsUseCaseProvider).call(
                        settings.copyWith(videoBrightness: value),
                      ),
                );
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('暗い'), Text('明るい')],
            ),
          ],
        ),
      ),
    );
  }
}
