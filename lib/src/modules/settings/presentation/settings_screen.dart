import 'package:flutter/material.dart';

import '../../media_access/data/app_info/app_info_adapter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({this.showAppBar = true, super.key});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: const SizedBox.shrink(),
              actions: [
                IconButton(
                  tooltip: 'アプリ情報',
                  onPressed: () => _showInformation(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            )
          : null,
      body: FutureBuilder<AppInfo>(
        future: const AppInfoAdapter().getAppInfo(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          final appName = info?.appName ?? 'ビデオ';
          final version = info?.versionName ?? '1.0.0';
          return SafeArea(
            top: !showAppBar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 28),
              children: [
                Center(
                  child: Icon(
                    Icons.video_library_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  appName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'バージョン $version',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '最新バージョンがインストールされています。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 120),
                FilledButton.tonal(
                  onPressed: () => _showTerms(context),
                  child: const Text('利用規約'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: appName,
                    applicationVersion: version,
                  ),
                  child: const Text('オープンソースライセンス'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showInformation(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ビデオについて'),
        content: const Text(
          '端末内の動画を検索、再生、整理するローカル動画アプリです。動画データは端末内で処理されます。',
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

  Future<void> _showTerms(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('利用規約'),
        content: const SingleChildScrollView(child: Text(_termsText)),
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

const String _termsText = '''
本アプリは、ユーザー本人が所有または利用権限を持つ端末内動画を閲覧・整理するためのアプリです。

共有、削除、移動、コピー、名前変更はユーザーの明示操作により実行されます。削除や移動の前に、対象と操作内容を確認してください。

端末、Android OS、外部アプリ、保存先ストレージの状態により、一部機能が利用できない場合があります。
''';
