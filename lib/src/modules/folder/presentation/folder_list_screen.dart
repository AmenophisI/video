import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../shared/utils/duration_format.dart';
import '../../../shared/utils/file_name_utils.dart';
import '../../media_access/data/file_operations/file_operation_adapter.dart';
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
  FolderSortKey _sortKey = FolderSortKey.name;
  FolderSortOrder _sortOrder = FolderSortOrder.ascending;

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(folderListProvider);

    return Stack(
      children: [
        foldersAsync.when(
          data: (folders) {
            final sortedFolders = _sortFolders(folders);
            if (sortedFolders.isEmpty) {
              return const Center(child: Text('フォルダが見つかりません'));
            }

            return Column(
              children: [
                _FolderSortToolbar(
                  sortKey: _sortKey,
                  sortOrder: _sortOrder,
                  onSortKeyChanged: (sortKey) {
                    setState(() {
                      _sortKey = sortKey;
                    });
                  },
                  onToggleFolderSortOrder: () {
                    setState(() {
                      _sortOrder = _sortOrder == FolderSortOrder.ascending
                          ? FolderSortOrder.descending
                          : FolderSortOrder.ascending;
                    });
                  },
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: sortedFolders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _FolderTile(folder: sortedFolders[index]);
                    },
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'create-folder',
            onPressed: () => _showCreateFolderDialog(context, ref),
            icon: const Icon(Icons.create_new_folder),
            label: const Text('フォルダ作成'),
          ),
        ),
      ],
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
    final videos = await ref
        .read(videoRepositoryProvider)
        .watchVideos(
          const VideoQuery(),
        )
        .first;
    if (!context.mounted) {
      return;
    }

    final relativePath = await showDialog<String>(
      context: context,
      builder: (context) => RelativePathPickerDialog(
        title: 'フォルダ作成',
        actionLabel: '作成',
        initialPath: 'Movies/NewFolder',
        inputLabel: '作成するフォルダ',
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

class _FolderSortToolbar extends StatelessWidget {
  const _FolderSortToolbar({
    required this.sortKey,
    required this.sortOrder,
    required this.onSortKeyChanged,
    required this.onToggleFolderSortOrder,
  });

  final FolderSortKey sortKey;
  final FolderSortOrder sortOrder;
  final ValueChanged<FolderSortKey> onSortKeyChanged;
  final VoidCallback onToggleFolderSortOrder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<FolderSortKey>(
              value: sortKey,
              decoration: const InputDecoration(
                labelText: 'フォルダ並び替え',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: FolderSortKey.name,
                  child: Text('フォルダ名'),
                ),
                DropdownMenuItem(
                  value: FolderSortKey.videoCount,
                  child: Text('動画件数'),
                ),
                DropdownMenuItem(
                  value: FolderSortKey.latestModifiedAt,
                  child: Text('更新日時'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSortKeyChanged(value);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: sortOrder == FolderSortOrder.ascending ? '昇順' : '降順',
            onPressed: onToggleFolderSortOrder,
            icon: Icon(
              sortOrder == FolderSortOrder.ascending
                  ? Icons.north
                  : Icons.south,
            ),
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

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final representativeVideo = folder.representativeVideoId == null
        ? null
        : ref
            .watch(videoByIdProvider(folder.representativeVideoId!))
            .valueOrNull;

    return Semantics(
      label: '${folder.name} フォルダ、動画${folder.videoCount}件',
      button: true,
      onTapHint: 'フォルダ内の動画を表示します',
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: SizedBox(
            width: 64,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: representativeVideo == null
                  ? ColoredBox(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.folder,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    )
                  : VideoThumbnail(video: representativeVideo),
            ),
          ),
          title: Text(
            folder.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              '${folder.videoCount}件',
              if (folder.totalSizeBytes != null)
                formatFileSize(folder.totalSizeBytes),
              if (folder.storageLabel?.isNotEmpty == true) folder.storageLabel!,
              if (folder.latestModifiedAt != null)
                '更新 ${formatDate(folder.latestModifiedAt)}',
            ].join(' ・ '),
          ),
          trailing: PopupMenuButton<_FolderAction>(
            key: ValueKey('folder-actions-${folder.id}'),
            onSelected: (action) async {
              switch (action) {
                case _FolderAction.open:
                  _openFolder(context);
                case _FolderAction.rename:
                  await _renameFolder(context, ref);
                case _FolderAction.delete:
                  await _deleteFolder(context, ref);
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
          ),
          onTap: () {
            _openFolder(context);
          },
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
