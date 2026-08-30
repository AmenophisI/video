import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/duration_format.dart';
import '../../../shared/utils/file_name_utils.dart';
import '../../media_access/data/file_operations/file_operation_adapter.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../../video/domain/video_query.dart';
import '../../video/presentation/widgets/relative_path_picker_dialog.dart';
import '../../video/presentation/widgets/video_thumbnail.dart';
import '../application/folder_providers.dart';
import '../domain/folder.dart';
import 'folder_videos_screen.dart';

class FolderListScreen extends ConsumerStatefulWidget {
  const FolderListScreen({super.key});

  @override
  ConsumerState<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends ConsumerState<FolderListScreen> {
  final FolderSortKey _sortKey = FolderSortKey.name;
  final FolderSortOrder _sortOrder = FolderSortOrder.ascending;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  final Set<String> _hiddenFolderIds = {};
  _FolderViewMode _viewMode = _FolderViewMode.list;
  String _searchText = '';
  bool _searchMode = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_restoreHiddenFolders);
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(folderListProvider);

    return PopScope<void>(
      canPop: !_searchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchMode) {
          setState(() {
            _searchMode = false;
            _searchText = '';
          });
        }
      },
      child: Stack(
        children: [
          foldersAsync.when(
            data: (folders) {
              final sortedFolders = _sortFolders(
                _filterFolders(
                  folders
                      .where((folder) => !_hiddenFolderIds.contains(folder.id))
                      .toList(growable: false),
                ),
              );

              return Column(
                children: [
                  if (_searchMode)
                    SafeArea(
                      bottom: false,
                      child: _FolderSearchBar(
                        onBack: () {
                          setState(() {
                            _searchMode = false;
                            _searchText = '';
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _searchText = value;
                          });
                        },
                      ),
                    )
                  else
                    SafeArea(
                      bottom: false,
                      child: _FolderSortToolbar(
                        viewMode: _viewMode,
                        onToggleViewMode: () {
                          setState(() {
                            _viewMode = _viewMode.next;
                          });
                        },
                        onSearch: () {
                          setState(() {
                            _searchMode = true;
                          });
                        },
                        onCreateFolder: () =>
                            _showCreateFolderDialog(context, ref),
                        onHideFolders: () => _showHiddenFolders(folders),
                        onOpenAbout: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: sortedFolders.isEmpty
                        ? const Center(child: Text('フォルダが見つかりません'))
                        : _viewMode != _FolderViewMode.list
                            ? GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 2, 14, 24),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      _viewMode == _FolderViewMode.enlarged
                                          ? 1
                                          : 3,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio:
                                      _viewMode == _FolderViewMode.enlarged
                                          ? 1.55
                                          : 0.92,
                                ),
                                itemCount: sortedFolders.length,
                                itemBuilder: (context, index) {
                                  return _FolderTile(
                                    folder: sortedFolders[index],
                                    displayMode: _FolderTileDisplayMode.grid,
                                  );
                                },
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: sortedFolders.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  return _FolderTile(
                                    folder: sortedFolders[index],
                                    displayMode: _FolderTileDisplayMode.list,
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
            error: (error, _) => Center(child: Text(error.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  List<Folder> _filterFolders(List<Folder> folders) {
    final keyword = _searchText.trim().toLowerCase();
    if (keyword.isEmpty) {
      return folders;
    }

    return folders.where((folder) {
      return folder.name.toLowerCase().contains(keyword) ||
          (folder.storageLabel?.toLowerCase().contains(keyword) ?? false);
    }).toList();
  }

  Future<void> _restoreHiddenFolders() async {
    final ids =
        await _preferences.getStringList(_hiddenFolderIdsPreferenceKey) ??
            const <String>[];
    if (!mounted) {
      return;
    }

    setState(() {
      _hiddenFolderIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _showHiddenFolders(List<Folder> folders) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _HiddenFoldersScreen(
          folders: folders,
          initiallyHidden: _hiddenFolderIds,
          onChanged: _setFolderHidden,
        ),
      ),
    );
  }

  Future<void> _setFolderHidden(String folderId, bool hidden) async {
    if (!mounted) {
      return;
    }

    setState(() {
      if (hidden) {
        _hiddenFolderIds.add(folderId);
      } else {
        _hiddenFolderIds.remove(folderId);
      }
    });
    await _preferences.setStringList(
      _hiddenFolderIdsPreferenceKey,
      _hiddenFolderIds.toList(growable: false),
    );
  }

  List<Folder> _sortFolders(List<Folder> folders) {
    final sorted = [...folders];
    sorted.sort((a, b) {
      final result = switch (_sortKey) {
        FolderSortKey.name => a.name.compareTo(b.name),
        FolderSortKey.videoCount => a.videoCount.compareTo(b.videoCount),
        FolderSortKey.latestModifiedAt =>
          (a.latestModifiedAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(b.latestModifiedAt?.millisecondsSinceEpoch ?? 0),
      };

      return _sortOrder == FolderSortOrder.ascending ? result : -result;
    });

    return sorted;
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController(text: 'フォルダ1');
    var folderName = controller.text;
    final selectedName = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('フォルダを作成'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'フォルダ名'),
            onChanged: (value) {
              setDialogState(() {
                folderName = value.trim();
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: folderName.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(folderName),
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      controller.dispose,
    );

    if (selectedName == null || selectedName.isEmpty) {
      return;
    }

    final relativePath = 'Movies/$selectedName';

    final validationMessage = validateRelativePath(relativePath);
    if (validationMessage != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)),
        );
      }
      return;
    }

    final normalizedPath = normalizeRelativePath(relativePath)!;

    try {
      await const FileOperationAdapter().createFolder(normalizedPath);
      await ref.read(scanVideosUseCaseProvider).call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フォルダを作成しました')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_folderCreateErrorMessage(error))),
        );
      }
    }
  }

  String _folderCreateErrorMessage(Object error) {
    if (error is PlatformException) {
      return switch (error.code) {
        'folder_already_exists' => '同名のフォルダが既にあります',
        'invalid_relative_path' => 'フォルダ名に使えない文字が含まれています',
        'folder_create_failed' => 'フォルダを作成できませんでした。保存先の状態を確認してください。',
        'invalid_arguments' => 'フォルダ名を入力してください',
        _ => error.message?.isNotEmpty == true
            ? 'フォルダ作成できませんでした: ${error.message}'
            : 'フォルダ作成できませんでした',
      };
    }

    return 'フォルダ作成できませんでした: $error';
  }
}

const String _hiddenFolderIdsPreferenceKey = 'folders.hiddenFolderIds';

class _HiddenFoldersScreen extends StatefulWidget {
  const _HiddenFoldersScreen({
    required this.folders,
    required this.initiallyHidden,
    required this.onChanged,
  });

  final List<Folder> folders;
  final Set<String> initiallyHidden;
  final Future<void> Function(String folderId, bool hidden) onChanged;

  @override
  State<_HiddenFoldersScreen> createState() => _HiddenFoldersScreenState();
}

class _HiddenFoldersScreenState extends State<_HiddenFoldersScreen> {
  late final Set<String> _hiddenFolderIds;

  @override
  void initState() {
    super.initState();
    _hiddenFolderIds = {...widget.initiallyHidden};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('フォルダを非表示')),
      body: ListView.builder(
        itemCount: widget.folders.length,
        itemBuilder: (context, index) {
          final folder = widget.folders[index];
          final lowerName = folder.name.toLowerCase();
          final canHide = lowerName != 'camera' && lowerName != 'download';
          final hidden = _hiddenFolderIds.contains(folder.id);

          return SwitchListTile(
            title: Text(folder.name),
            subtitle: Text('${folder.videoCount}件'),
            value: hidden,
            onChanged: canHide
                ? (value) {
                    setState(() {
                      if (value) {
                        _hiddenFolderIds.add(folder.id);
                      } else {
                        _hiddenFolderIds.remove(folder.id);
                      }
                    });
                    unawaited(widget.onChanged(folder.id, value));
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _FolderSearchBar extends StatelessWidget {
  const _FolderSearchBar({required this.onBack, required this.onChanged});

  final VoidCallback onBack;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(13, 0, 13, 8),
      child: TextField(
        autofocus: true,
        decoration: InputDecoration(
          prefixIcon: IconButton(
            tooltip: '戻る',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          hintText: '検索',
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _FolderSortToolbar extends StatelessWidget {
  const _FolderSortToolbar({
    required this.viewMode,
    required this.onToggleViewMode,
    required this.onSearch,
    required this.onCreateFolder,
    required this.onHideFolders,
    required this.onOpenAbout,
  });

  final _FolderViewMode viewMode;
  final VoidCallback onToggleViewMode;
  final VoidCallback onSearch;
  final VoidCallback onCreateFolder;
  final VoidCallback onHideFolders;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 3, 12, 8),
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            tooltip: viewMode.next.label,
            color: Theme.of(context).colorScheme.primary,
            onPressed: onToggleViewMode,
            icon: Icon(viewMode.next.icon),
          ),
          IconButton(
            tooltip: '検索',
            onPressed: onSearch,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<_FolderMenuAction>(
            tooltip: 'その他',
            onSelected: (action) {
              switch (action) {
                case _FolderMenuAction.edit:
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('フォルダを編集'),
                      content: const Text('各フォルダのメニューから名前変更または削除を選択できます。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                case _FolderMenuAction.create:
                  onCreateFolder();
                case _FolderMenuAction.hide:
                  onHideFolders();
                case _FolderMenuAction.about:
                  onOpenAbout();
                case _FolderMenuAction.contact:
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
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _FolderMenuAction.edit,
                child: Text('編集'),
              ),
              PopupMenuItem(
                value: _FolderMenuAction.create,
                child: Text('フォルダを作成'),
              ),
              PopupMenuItem(
                value: _FolderMenuAction.hide,
                child: Text('フォルダを非表示'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _FolderMenuAction.about,
                child: Text('ビデオについて'),
              ),
              PopupMenuItem(
                value: _FolderMenuAction.contact,
                child: Text('お問い合わせ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum FolderSortKey {
  name,
  videoCount,
  latestModifiedAt,
}

enum FolderSortOrder {
  ascending,
  descending,
}

enum _FolderViewMode {
  list,
  grid,
  enlarged,
}

extension on _FolderViewMode {
  _FolderViewMode get next => switch (this) {
        _FolderViewMode.list => _FolderViewMode.grid,
        _FolderViewMode.grid => _FolderViewMode.enlarged,
        _FolderViewMode.enlarged => _FolderViewMode.list,
      };

  String get label => switch (this) {
        _FolderViewMode.list => 'リスト表示',
        _FolderViewMode.grid => 'グリッド表示',
        _FolderViewMode.enlarged => '拡大表示',
      };

  IconData get icon => switch (this) {
        _FolderViewMode.list => Icons.view_list,
        _FolderViewMode.grid => Icons.grid_view,
        _FolderViewMode.enlarged => Icons.view_agenda_outlined,
      };
}

enum _FolderMenuAction {
  edit,
  create,
  hide,
  about,
  contact,
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({
    required this.folder,
    required this.displayMode,
  });

  final Folder folder;
  final _FolderTileDisplayMode displayMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final representativeVideo = folder.representativeVideoId == null
        ? null
        : ref
            .watch(videoByIdProvider(folder.representativeVideoId!))
            .valueOrNull;

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(
          displayMode == _FolderTileDisplayMode.grid ? 16 : 11),
      child: representativeVideo == null
          ? ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.folder_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : VideoThumbnail(video: representativeVideo),
    );

    final subtitle = [
      '${folder.videoCount}件',
      if (folder.totalSizeBytes != null) formatFileSize(folder.totalSizeBytes),
      if (folder.storageLabel?.isNotEmpty == true) folder.storageLabel!,
      if (folder.latestModifiedAt != null)
        '更新 ${formatDate(folder.latestModifiedAt)}',
    ].join(' ・ ');

    return Semantics(
      container: true,
      label: '${folder.name} フォルダ、動画${folder.videoCount}件',
      button: true,
      onTapHint: 'フォルダ内の動画を表示します',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _openFolder(context);
            },
            child: displayMode == _FolderTileDisplayMode.grid
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            thumbnail,
                            Positioned(
                              right: 2,
                              top: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surface
                                      .withValues(alpha: 0.88),
                                  shape: BoxShape.circle,
                                ),
                                child: _FolderActionsButton(folder: folder),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        folder.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        '${folder.videoCount}件',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  )
                : ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    leading: SizedBox(
                      width: 60,
                      height: 42,
                      child: thumbnail,
                    ),
                    title: Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _FolderActionsButton(folder: folder),
                  ),
          ),
        ),
      ),
    );
  }

  void _openFolder(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FolderVideosScreen(folder: folder),
      ),
    );
  }

  Future<void> _renameFolder(BuildContext context, WidgetRef ref) async {
    final videos = await ref.read(folderVideosProvider(folder.id).future);
    if (!context.mounted) {
      return;
    }

    final currentPath = _initialFolderPath(videos);
    final relativePath = await showDialog<String>(
      context: context,
      builder: (context) => RelativePathPickerDialog(
        title: 'フォルダ名変更',
        actionLabel: '変更',
        initialPath: currentPath,
        inputLabel: '変更後のフォルダ',
        folderOptions:
            videos.map((video) => video.relativePath).whereType<String>(),
      ),
    );

    if (relativePath == null || relativePath.isEmpty) {
      return;
    }

    final validationMessage = validateRelativePath(relativePath);
    if (validationMessage != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)),
        );
      }
      return;
    }

    final normalizedPath = normalizeRelativePath(relativePath)!;
    final conflicts = await _findDestinationConflicts(
      ref,
      movingVideos: videos,
      relativePath: normalizedPath,
    );
    if (conflicts.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移動先に同名の動画が${conflicts.length}件あります')),
        );
      }
      return;
    }

    final progress = ValueNotifier(
      _FolderBatchProgress(label: 'フォルダ名変更中', current: 0, total: videos.length),
    );
    if (context.mounted) {
      unawaited(_showFolderProgressDialog(context, progress));
      await Future<void>.delayed(Duration.zero);
    }

    var successCount = 0;
    var failureCount = 0;
    var wasCancelled = false;
    Object? operationError;
    try {
      final repository = ref.read(videoRepositoryProvider);
      for (var index = 0; index < videos.length; index += 1) {
        if (progress.value.cancelRequested) {
          break;
        }

        progress.value = progress.value.copyWith(current: index + 1);
        try {
          await repository.moveVideo(
            videoId: videos[index].id,
            relativePath: normalizedPath,
          );
          successCount += 1;
        } catch (_) {
          failureCount += 1;
        }
      }
      wasCancelled = progress.value.cancelRequested;
      await ref.read(scanVideosUseCaseProvider).call();
    } catch (error) {
      operationError = error;
    } finally {
      wasCancelled = progress.value.cancelRequested;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
    }

    if (!context.mounted) {
      return;
    }

    if (operationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フォルダ名変更できませんでした: $operationError')),
      );
      return;
    }

    final suffix = _operationSummary(
      successCount: successCount,
      failureCount: failureCount,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasCancelled ? 'フォルダ名変更をキャンセルしました$suffix' : 'フォルダ内の動画を移動しました$suffix',
        ),
      ),
    );
  }

  Future<void> _deleteFolder(BuildContext context, WidgetRef ref) async {
    final videos = await ref.read(folderVideosProvider(folder.id).future);
    if (!context.mounted) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォルダ削除'),
        content: Text('${folder.name} 内の${videos.length}件の動画を端末から削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    final progress = ValueNotifier(
      _FolderBatchProgress(label: 'フォルダ削除中', current: 0, total: videos.length),
    );
    if (context.mounted) {
      unawaited(_showFolderProgressDialog(context, progress));
      await Future<void>.delayed(Duration.zero);
    }

    var successCount = 0;
    var failureCount = 0;
    var wasCancelled = false;
    Object? operationError;
    try {
      final repository = ref.read(videoRepositoryProvider);
      for (var index = 0; index < videos.length; index += 1) {
        if (progress.value.cancelRequested) {
          break;
        }

        progress.value = progress.value.copyWith(current: index + 1);
        try {
          await repository.deleteVideo(videos[index].id);
          successCount += 1;
        } catch (_) {
          failureCount += 1;
        }
      }
      wasCancelled = progress.value.cancelRequested;
      await ref.read(scanVideosUseCaseProvider).call();
    } catch (error) {
      operationError = error;
    } finally {
      wasCancelled = progress.value.cancelRequested;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
    }

    if (!context.mounted) {
      return;
    }

    if (operationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('フォルダ削除できませんでした: $operationError')),
      );
      return;
    }

    final suffix = _operationSummary(
      successCount: successCount,
      failureCount: failureCount,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasCancelled ? 'フォルダ削除をキャンセルしました$suffix' : 'フォルダ内の動画を削除しました$suffix',
        ),
      ),
    );
  }

  Future<void> _showFolderProgressDialog(
    BuildContext context,
    ValueNotifier<_FolderBatchProgress> progress,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<_FolderBatchProgress>(
          valueListenable: progress,
          builder: (context, value, _) {
            final progressValue = value.total <= 0
                ? null
                : (value.current / value.total).clamp(0, 1).toDouble();

            return AlertDialog(
              title: Text(value.label),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: progressValue),
                  const SizedBox(height: 12),
                  Text(
                    value.cancelRequested
                        ? 'キャンセル中... ${value.current} / ${value.total}'
                        : '${value.current} / ${value.total}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'アプリを閉じた場合は、完了済みの動画だけを反映し、次回起動時に一覧を再スキャンします。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: value.cancelRequested
                      ? null
                      : () {
                          progress.value = value.copyWith(
                            cancelRequested: true,
                          );
                        },
                  child: const Text('キャンセル'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _operationSummary({
    required int successCount,
    required int failureCount,
  }) {
    final summary = [
      if (successCount > 0) '$successCount件完了',
      if (failureCount > 0) '$failureCount件失敗',
    ].join(' / ');

    return summary.isEmpty ? '' : '（$summary）';
  }

  String _initialFolderPath(List<Video> videos) {
    final path = videos.firstOrNull?.relativePath;
    if (path == null || path.isEmpty) {
      return 'Movies/${folder.name}';
    }

    return path.replaceAll(RegExp(r'/$'), '');
  }

  Future<List<Video>> _findDestinationConflicts(
    WidgetRef ref, {
    required List<Video> movingVideos,
    required String relativePath,
  }) async {
    final movingIds = movingVideos.map((video) => video.id).toSet();
    final movingNames =
        movingVideos.map((video) => video.displayName.toLowerCase()).toSet();
    final repository = ref.read(videoRepositoryProvider);
    final publicVideos = await repository.watchVideos(const VideoQuery()).first;
    final privateVideos = await repository
        .watchVideos(const VideoQuery(filter: VideoFilter.privateVideos))
        .first;
    final allVideos = {
      for (final video in [...publicVideos, ...privateVideos]) video.id: video,
    }.values;

    return [
      for (final video in allVideos)
        if (!movingIds.contains(video.id) &&
            normalizeRelativePath(video.relativePath ?? '') == relativePath &&
            movingNames.contains(video.displayName.toLowerCase()))
          video,
    ];
  }
}

class _FolderActionsButton extends ConsumerWidget {
  const _FolderActionsButton({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_FolderAction>(
      key: ValueKey('folder-actions-${folder.id}'),
      onSelected: (action) async {
        final tile = _FolderTile(
          folder: folder,
          displayMode: _FolderTileDisplayMode.list,
        );
        switch (action) {
          case _FolderAction.open:
            tile._openFolder(context);
          case _FolderAction.rename:
            await tile._renameFolder(context, ref);
          case _FolderAction.delete:
            await tile._deleteFolder(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _FolderAction.open,
          child: ListTile(
            leading: Icon(Icons.chevron_right),
            title: Text('開く'),
          ),
        ),
        PopupMenuItem(
          value: _FolderAction.rename,
          child: ListTile(
            leading: Icon(Icons.drive_file_move_outline),
            title: Text('フォルダ名変更'),
          ),
        ),
        PopupMenuItem(
          value: _FolderAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('フォルダ削除'),
          ),
        ),
      ],
    );
  }
}

enum _FolderTileDisplayMode {
  grid,
  list,
}

enum _FolderAction {
  open,
  rename,
  delete,
}

class _FolderBatchProgress {
  const _FolderBatchProgress({
    required this.label,
    required this.current,
    required this.total,
    this.cancelRequested = false,
  });

  final String label;
  final int current;
  final int total;
  final bool cancelRequested;

  _FolderBatchProgress copyWith({
    String? label,
    int? current,
    int? total,
    bool? cancelRequested,
  }) {
    return _FolderBatchProgress(
      label: label ?? this.label,
      current: current ?? this.current,
      total: total ?? this.total,
      cancelRequested: cancelRequested ?? this.cancelRequested,
    );
  }
}
