import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../media_access/data/app_info/app_info_adapter.dart';
import '../../media_access/domain/media_permission.dart';
import '../../media_access/data/thumbnails/thumbnail_cache.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video_query.dart';
import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final permissionAsync = ref.watch(mediaPermissionProvider);
    final query = ref.watch(videoQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            permissionAsync.when(
              data: (permission) => _PermissionTile(permission: permission),
              error: (error, _) => ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('権限状態'),
                subtitle: Text(error.toString()),
              ),
              loading: () => const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('権限状態を確認中'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref
                          .read(mediaPermissionAdapterProvider)
                          .requestPermission();
                      ref.invalidate(mediaPermissionProvider);
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text('権限を再確認'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref
                          .read(mediaPermissionAdapterProvider)
                          .requestAdditionalVideoAccess();
                      ref.invalidate(mediaPermissionProvider);
                      await ref.read(scanVideosUseCaseProvider).call();
                    },
                    icon: const Icon(Icons.video_settings),
                    label: const Text('アクセス動画を選択'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(mediaPermissionAdapterProvider)
                          .openAppSettings();
                    },
                    icon: const Icon(Icons.settings_applications),
                    label: const Text('Android設定'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('再生位置を保存'),
              value: settings.rememberPlaybackPosition,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings.copyWith(rememberPlaybackPosition: value),
                );
              },
            ),
            SwitchListTile(
              title: const Text('視聴進捗バーを表示'),
              value: settings.showPlaybackProgress,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings.copyWith(showPlaybackProgress: value),
                );
              },
            ),
            SwitchListTile(
              title: const Text('動画タグを表示'),
              value: settings.showVideoTags,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings.copyWith(showVideoTags: value),
                );
              },
            ),
            SwitchListTile(
              title: const Text('簡易再生を有効にする'),
              value: settings.enableInstantPlayer,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings.copyWith(enableInstantPlayer: value),
                );
              },
            ),
            const Divider(height: 1),
            _SettingsControlSection(
              icon: Icon(
                settings.hasPrivatePin ? Icons.lock : Icons.lock_open,
              ),
              title: 'プライベートPIN',
              subtitle: settings.hasPrivatePin
                  ? '設定済み'
                  : settings.privateLockMethod ==
                          PrivateLockMethod.deviceCredential
                      ? '未設定（端末認証のみ）'
                      : '未設定',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _showPinDialog(context, ref, settings),
                    icon: const Icon(Icons.pin),
                    label: Text(settings.hasPrivatePin ? '変更' : '設定'),
                  ),
                  if (settings.hasPrivatePin)
                    OutlinedButton.icon(
                      onPressed: () {
                        _updateSettings(
                          ref,
                          settings.copyWith(clearPrivatePin: true),
                        );
                      },
                      icon: const Icon(Icons.lock_open),
                      label: const Text('解除'),
                    ),
                ],
              ),
            ),
            _SettingsControlSection(
              icon: const Icon(Icons.fingerprint),
              title: 'プライベートロック方式',
              subtitle: settings.privateLockMethod.label,
              child: DropdownButtonFormField<PrivateLockMethod>(
                value: settings.privateLockMethod,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ロック方式',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final method in PrivateLockMethod.values)
                    DropdownMenuItem(
                      value: method,
                      child: Text(
                        method.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (method) {
                  if (method == null) {
                    return;
                  }

                  _updateSettings(
                    ref,
                    settings.copyWith(privateLockMethod: method),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.grid_view),
                    label: const Text('グリッド'),
                    selected: settings.viewMode == LibraryViewMode.grid,
                    onSelected: (_) {
                      _updateSettings(
                        ref,
                        settings.copyWith(viewMode: LibraryViewMode.grid),
                      );
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.view_list),
                    label: const Text('リスト'),
                    selected: settings.viewMode == LibraryViewMode.list,
                    onSelected: (_) {
                      _updateSettings(
                        ref,
                        settings.copyWith(viewMode: LibraryViewMode.list),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<VideoSortKey>(
                      value: query.sortKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '初期並び替え',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: VideoSortKey.modifiedAt,
                          child: Text('更新日時'),
                        ),
                        DropdownMenuItem(
                          value: VideoSortKey.createdAt,
                          child: Text('作成日時'),
                        ),
                        DropdownMenuItem(
                          value: VideoSortKey.title,
                          child: Text('タイトル'),
                        ),
                        DropdownMenuItem(
                          value: VideoSortKey.duration,
                          child: Text('再生時間'),
                        ),
                        DropdownMenuItem(
                          value: VideoSortKey.sizeBytes,
                          child: Text('サイズ'),
                        ),
                      ],
                      onChanged: (sortKey) async {
                        if (sortKey == null) {
                          return;
                        }

                        final nextQuery = query.copyWith(sortKey: sortKey);
                        ref.read(videoQueryProvider.notifier).state = nextQuery;
                        await ref
                            .read(videoQueryPreferencesStoreProvider)
                            .save(nextQuery);
                      },
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip:
                        query.sortOrder == SortOrder.descending ? '降順' : '昇順',
                    onPressed: () async {
                      final nextOrder = query.sortOrder == SortOrder.descending
                          ? SortOrder.ascending
                          : SortOrder.descending;
                      final nextQuery = query.copyWith(sortOrder: nextOrder);
                      ref.read(videoQueryProvider.notifier).state = nextQuery;
                      await ref
                          .read(videoQueryPreferencesStoreProvider)
                          .save(nextQuery);
                    },
                    icon: Icon(
                      query.sortOrder == SortOrder.descending
                          ? Icons.south
                          : Icons.north,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('動画スキャンを再実行'),
              subtitle: const Text('端末内の動画一覧とインデックスを更新します'),
              onTap: () => _rescanVideos(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('サムネイルキャッシュ上限'),
              subtitle: Text('${settings.thumbnailCacheLimitMb} MB'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Slider(
                min: 64,
                max: 1024,
                divisions: 15,
                label: '${settings.thumbnailCacheLimitMb} MB',
                value:
                    settings.thumbnailCacheLimitMb.clamp(64, 1024).toDouble(),
                onChanged: (value) {
                  _updateSettings(
                    ref,
                    settings.copyWith(
                      thumbnailCacheLimitMb: value.round(),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('サムネイルキャッシュを削除'),
              onTap: () async {
                await const ThumbnailCache().clear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('キャッシュを削除しました')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_search),
              title: const Text('検索履歴を削除'),
              onTap: () async {
                await ref.read(videoRepositoryProvider).clearSearchHistory();
                ref.invalidate(searchHistoryProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('検索履歴を削除しました')),
                  );
                }
              },
            ),
            const Divider(height: 1),
            const _AppInfoSection(),
          ],
        ),
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _updateSettings(WidgetRef ref, AppSettings settings) {
    ref.read(updateSettingsUseCaseProvider).call(settings);
  }

  Future<void> _rescanVideos(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(scanVideosUseCaseProvider).call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('動画スキャンを実行しました')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('動画スキャンに失敗しました: $error')),
        );
      }
    }
  }

  Future<void> _showPinDialog(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(settings.hasPrivatePin ? 'PINを変更' : 'PINを設定'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: '4〜8桁のPIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (pin == null) {
      return;
    }

    if (!RegExp(r'^\d{4,8}$').hasMatch(pin)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINは数字4〜8桁で設定してください')),
        );
      }
      return;
    }

    _updateSettings(ref, settings.copyWith(privatePin: pin));
  }
}

class _SettingsControlSection extends StatelessWidget {
  const _SettingsControlSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: IconTheme.merge(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: icon,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 10),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  const _AppInfoSection();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInfo>(
      future: const AppInfoAdapter().getAppInfo(),
      builder: (context, snapshot) {
        final appInfo = snapshot.data;
        final versionText = appInfo?.versionLabel ?? '取得中';

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('アプリ情報'),
              subtitle: Text('バージョン $versionText'),
              onTap: () => _showTextDialog(
                context,
                title: 'アプリ情報',
                content: [
                  appInfo?.appName ?? '動画ライブラリ',
                  '端末内の動画をMediaStore経由で取得し、検索、再生、整理を行うローカル動画管理アプリです。',
                  if (appInfo?.packageName.isNotEmpty == true)
                    'パッケージ: ${appInfo!.packageName}',
                  'バージョン: $versionText',
                ].join('\n\n'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('利用規約'),
              onTap: () => _showTextDialog(
                context,
                title: '利用規約',
                content: _termsText,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('プライバシーポリシー'),
              onTap: () => _showTextDialog(
                context,
                title: 'プライバシーポリシー',
                content: _privacyPolicyText,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTextDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          FilledButton(
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

動画の共有、削除、移動、コピー、名前変更はユーザーの明示操作により実行されます。削除や移動などの操作を行う前に、対象ファイルと操作内容を確認してください。

本アプリは、端末やAndroid OS、外部アプリ、保存先ストレージの状態により、一部機能が利用できない場合があります。
''';

const String _privacyPolicyText = '''
本アプリは、動画一覧表示、検索、再生、整理のために、端末内の動画メタデータとアプリ内設定を端末内で処理します。

動画ファイル、ファイル名、保存場所、再生位置、検索履歴、プライベート設定、プレイリスト情報は端末内に保存され、外部サーバーへ送信しません。

共有操作を実行した場合のみ、ユーザーが選択した外部アプリへ対象動画のContent URIを一時的な読み取り権限付きで渡します。

ユーザーはAndroidの設定画面から、いつでも動画アクセス権限を変更できます。
''';

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.permission});

  final MediaPermission permission;

  @override
  Widget build(BuildContext context) {
    final text = switch (permission) {
      MediaPermission.granted => 'すべての動画にアクセス可能',
      MediaPermission.limited => '選択した動画のみアクセス可能',
      MediaPermission.denied => '拒否されています',
      MediaPermission.unknown => '不明',
    };

    return ListTile(
      leading: Icon(
        permission.canReadVideos ? Icons.verified_user : Icons.lock_outline,
      ),
      title: const Text('権限状態'),
      subtitle: Text(text),
    );
  }
}
