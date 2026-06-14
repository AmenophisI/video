import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/file_name_utils.dart';
import '../../folder/presentation/folder_list_screen.dart';
import '../../media_access/domain/media_permission.dart';
import '../../playback/presentation/full_screen_player_screen.dart';
import '../../playback/presentation/quick_preview_sheet.dart';
import '../../playlist/presentation/playlist_list_screen.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/private_access_auth.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/video_providers.dart';
import '../domain/video.dart';
import '../domain/video_query.dart';
import 'video_detail_screen.dart';
import 'widgets/file_conflict_dialog.dart';
import 'widgets/relative_path_picker_dialog.dart';
import 'widgets/video_thumbnail.dart';
import 'widgets/video_tile.dart';

class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen> {
  final Set<String> _selectedVideoIds = {};
  late final _LifecycleObserver _lifecycleObserver;
  StreamSubscription<void>? _mediaStoreSubscription;

  bool get _isSelectionMode => _selectedVideoIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    Future.microtask(_restoreQueryPreferences);
    _lifecycleObserver = _LifecycleObserver(onResume: () {
      ref.invalidate(mediaPermissionProvider);
      ref.read(scanVideosUseCaseProvider).call();
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _mediaStoreSubscription =
        ref.read(mediaStoreAdapterProvider).watchChanges().listen((_) {
      ref.read(scanVideosUseCaseProvider).call();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _mediaStoreSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VideoQuery>(videoQueryProvider, (previous, next) {
      if (previous == null || _isSameQuery(previous, next)) {
        return;
      }

      if (_selectedVideoIds.isNotEmpty && mounted) {
        setState(_selectedVideoIds.clear);
      }
    });

    final videosAsync = ref.watch(videoLibraryProvider);
    final permissionAsync = ref.watch(mediaPermissionProvider);
    final query = ref.watch(videoQueryProvider);
    final settings = ref.watch(appSettingsProvider).maybeWhen(
          data: (settings) => settings,
          orElse: () => null,
        );

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                tooltip: '選択解除',
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          _isSelectionMode ? '${_selectedVideoIds.length}件選択中' : '動画ライブラリ',
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  tooltip: '全選択',
                  onPressed: _selectAllVisible,
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: '共有',
                  onPressed: _shareSelected,
                  icon: const Icon(Icons.ios_share),
                ),
                IconButton(
                  tooltip: '移動',
                  onPressed: () => unawaited(_moveOrCopySelected(isMove: true)),
                  icon: const Icon(Icons.drive_file_move_outline),
                ),
                IconButton(
                  tooltip: 'コピー',
                  onPressed: () =>
                      unawaited(_moveOrCopySelected(isMove: false)),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  tooltip: '削除',
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
              ]
            : [
                IconButton(
                  tooltip: '再スキャン',
                  onPressed: () => ref.read(scanVideosUseCaseProvider).call(),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: '設定',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                ),
              ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.video_library), text: '動画'),
                Tab(icon: Icon(Icons.folder), text: 'フォルダ'),
                Tab(icon: Icon(Icons.playlist_play), text: 'リスト'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      _LibraryToolbar(query: query),
                      Expanded(
                        child: permissionAsync.when(
                          data: (permission) {
                            if (!permission.canReadVideos) {
                              return _PermissionRequiredPanel(
                                onRequestPermission: _requestPermission,
                                onOpenSettings: _openAppSettings,
                              );
                            }

                            return videosAsync.when(
                              data: (videos) => Column(
                                children: [
                                  if (permission == MediaPermission.limited)
                                    _LimitedPermissionBanner(
                                      onRequestAdditionalAccess:
                                          _requestAdditionalVideoAccess,
                                      onOpenSettings: _openAppSettings,
                                    ),
                                  Expanded(
                                    child: VideoGrid(
                                      videos: videos,
                                      showPlaybackProgress:
                                          settings?.showPlaybackProgress ??
                                              true,
                                      showTags: settings?.showVideoTags ?? true,
                                      enableInstantPlayer:
                                          settings?.enableInstantPlayer ?? true,
                                      viewMode: settings?.viewMode ??
                                          LibraryViewMode.grid,
                                      selectedVideoIds: _selectedVideoIds,
                                      selectionMode: _isSelectionMode,
                                      onToggleSelection: _toggleSelection,
                                      onStartSelection: _startSelection,
                                    ),
                                  ),
                                ],
                              ),
                              error: (error, _) =>
                                  Center(child: Text(error.toString())),
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          error: (error, _) =>
                              Center(child: Text(error.toString())),
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const FolderListScreen(),
                  const PlaylistListScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startSelection(String videoId) {
    setState(() {
      _selectedVideoIds.add(videoId);
    });
  }

  void _toggleSelection(String videoId) {
    setState(() {
      if (_selectedVideoIds.contains(videoId)) {
        _selectedVideoIds.remove(videoId);
      } else {
        _selectedVideoIds.add(videoId);
      }
    });
  }

  void _clearSelection() {
    setState(_selectedVideoIds.clear);
  }

  bool _isSameQuery(VideoQuery a, VideoQuery b) {
    return a.searchText == b.searchText &&
        a.searchTarget == b.searchTarget &&
        a.folderId == b.folderId &&
        a.sortKey == b.sortKey &&
        a.sortOrder == b.sortOrder &&
        a.filter == b.filter;
  }

  void _selectAllVisible() {
    final videos =
        ref.read(videoLibraryProvider).valueOrNull ?? const <Video>[];
    setState(() {
      _selectedVideoIds
        ..clear()
        ..addAll(videos.map((video) => video.id));
    });
  }

  Future<void> _shareSelected() async {
    final ids = _selectedVideoIds.toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).shareVideos(ids);
      _clearSelection();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _moveOrCopySelected({required bool isMove}) async {
    final ids = _selectedVideoIds.toList(growable: false);
    if (ids.isEmpty) {
      return;
    }

    final knownVideos = await _loadKnownVideos();
    if (!mounted) {
      return;
    }

    final relativePath = await showDialog<String>(
      context: context,
      builder: (context) => RelativePathPickerDialog(
        title: isMove ? '選択動画を移動' : '選択動画をコピー',
        actionLabel: isMove ? '移動' : 'コピー',
        initialPath: 'Movies',
        inputLabel: isMove ? '移動先フォルダ' : 'コピー先フォルダ',
        folderOptions:
            knownVideos.map((video) => video.relativePath).whereType<String>(),
      ),
    );

    if (relativePath == null || relativePath.isEmpty) {
      return;
    }

    final validationMessage = validateRelativePath(relativePath);
    if (validationMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(validationMessage)),
        );
      }
      return;
    }

    final normalizedPath = normalizeRelativePath(relativePath)!;
    final knownVideosById = {for (final video in knownVideos) video.id: video};
    final selectedVideos = [
      for (final id in ids)
        if (knownVideosById[id] != null) knownVideosById[id]!,
    ];
    final plannedNames = <String>{};
    final conflictCount = selectedVideos.where((video) {
      final lowerName = video.displayName.toLowerCase();
      final hasExistingConflict = _findDuplicateVideo(
            knownVideos,
            relativePath: normalizedPath,
            displayName: video.displayName,
            exceptVideoId: isMove ? video.id : null,
          ) !=
          null;
      final hasBatchConflict = !plannedNames.add(lowerName);
      return hasExistingConflict || hasBatchConflict;
    }).length;

    FileConflictResolution? conflictResolution;
    if (conflictCount > 0) {
      if (!mounted) {
        return;
      }
      conflictResolution = await showFileConflictDialog(
        context: context,
        isMove: isMove,
        isBatch: true,
        conflictCount: conflictCount,
      );
      if (conflictResolution == null || !mounted) {
        return;
      }
    }

    try {
      final repository = ref.read(videoRepositoryProvider);
      final videosById = knownVideosById;
      final destinationVideos = knownVideos.toList();
      final destinationNames = knownVideos
          .where((video) =>
              normalizeRelativePath(video.relativePath ?? '') == normalizedPath)
          .map((video) => video.displayName)
          .toList();
      var skippedCount = 0;
      var successCount = 0;
      var failureCount = 0;
      var wasCancelled = false;
      final progress = ValueNotifier(
        _BatchProgress(
          label: isMove ? '移動中' : 'コピー中',
          current: 0,
          total: ids.length,
        ),
      );
      if (mounted) {
        unawaited(_showBatchProgressDialog(context, progress));
        await Future<void>.delayed(Duration.zero);
      }

      try {
        for (var index = 0; index < ids.length; index += 1) {
          if (progress.value.cancelRequested) {
            break;
          }

          final id = ids[index];
          progress.value = progress.value.copyWith(current: index + 1);
          final video = videosById[id];
          if (video == null) {
            skippedCount += 1;
            continue;
          }

          try {
            var targetDisplayName = video.displayName;
            final conflictVideo = _findDuplicateVideo(
              destinationVideos,
              relativePath: normalizedPath,
              displayName: video.displayName,
              exceptVideoId: isMove ? video.id : null,
            );
            if (conflictVideo != null) {
              switch (conflictResolution) {
                case FileConflictResolution.skip:
                  skippedCount += 1;
                  continue;
                case FileConflictResolution.rename:
                  if (isMove) {
                    skippedCount += 1;
                    continue;
                  }
                  targetDisplayName = nextAvailableDisplayName(
                    desiredDisplayName: video.displayName,
                    existingDisplayNames: destinationNames,
                  );
                case FileConflictResolution.replace:
                  await repository.deleteVideo(conflictVideo.id);
                  destinationVideos
                      .removeWhere((video) => video.id == conflictVideo.id);
                  destinationNames.removeWhere(
                    (name) =>
                        name.toLowerCase() ==
                        conflictVideo.displayName.toLowerCase(),
                  );
                case null:
                  skippedCount += 1;
                  continue;
              }
            }

            if (isMove) {
              await repository.moveVideo(
                videoId: id,
                relativePath: normalizedPath,
              );
              destinationNames.add(targetDisplayName);
              destinationVideos
                ..removeWhere((knownVideo) => knownVideo.id == video.id)
                ..add(video);
              successCount += 1;
            } else {
              final copyDisplayName = conflictVideo == null
                  ? nextAvailableDisplayName(
                      desiredDisplayName: targetDisplayName,
                      existingDisplayNames: destinationNames,
                    )
                  : targetDisplayName;
              await repository.copyVideo(
                videoId: id,
                relativePath: normalizedPath,
                displayName: copyDisplayName,
              );
              destinationNames.add(copyDisplayName);
              destinationVideos.add(
                video.copyWith(
                  displayName: copyDisplayName,
                  relativePath: normalizedPath,
                ),
              );
              successCount += 1;
            }
          } catch (_) {
            failureCount += 1;
          }
        }
      } finally {
        wasCancelled = progress.value.cancelRequested;
        await _rescanAfterFileOperation();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        progress.dispose();
      }
      _clearSelection();
      if (mounted) {
        final suffix = [
          if (successCount > 0) '$successCount件完了',
          if (skippedCount > 0) '$skippedCount件スキップ',
          if (failureCount > 0) '$failureCount件失敗',
        ].join(' / ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (wasCancelled
                      ? '${isMove ? '移動' : 'コピー'}をキャンセルしました'
                      : '${isMove ? '移動' : 'コピー'}が完了しました') +
                  (suffix.isEmpty ? '' : '（$suffix）'),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isMove ? '移動' : 'コピー'}できませんでした: $error')),
        );
      }
    }
  }

  Future<List<Video>> _loadKnownVideos() async {
    final repository = ref.read(videoRepositoryProvider);
    final publicVideos = await repository.watchVideos(const VideoQuery()).first;
    final privateVideos = await repository
        .watchVideos(const VideoQuery(filter: VideoFilter.privateVideos))
        .first;

    return {
      for (final video in [...publicVideos, ...privateVideos]) video.id: video,
    }.values.toList(growable: false);
  }

  Video? _findDuplicateVideo(
    List<Video> videos, {
    required String relativePath,
    required String displayName,
    String? exceptVideoId,
  }) {
    final normalizedPath = normalizeRelativePath(relativePath);
    for (final video in videos) {
      if (video.id == exceptVideoId) {
        continue;
      }

      if (normalizeRelativePath(video.relativePath ?? '') == normalizedPath &&
          video.displayName.toLowerCase() == displayName.toLowerCase()) {
        return video;
      }
    }

    return null;
  }

  Future<void> _showBatchProgressDialog(
    BuildContext context,
    ValueNotifier<_BatchProgress> progress,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<_BatchProgress>(
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

  Future<void> _deleteSelected() async {
    final count = _selectedVideoIds.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除'),
        content: Text('選択中の$count件を端末から削除します。'),
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

    final ids = _selectedVideoIds.toList(growable: false);
    final progress = ValueNotifier(
      _BatchProgress(label: '削除中', current: 0, total: ids.length),
    );
    if (mounted) {
      unawaited(_showBatchProgressDialog(context, progress));
      await Future<void>.delayed(Duration.zero);
    }

    Object? deleteError;
    var successCount = 0;
    var failureCount = 0;
    var wasCancelled = false;
    try {
      final repository = ref.read(videoRepositoryProvider);
      for (var index = 0; index < ids.length; index += 1) {
        if (progress.value.cancelRequested) {
          break;
        }

        progress.value = progress.value.copyWith(current: index + 1);
        try {
          await repository.deleteVideo(ids[index]);
          successCount += 1;
        } catch (_) {
          failureCount += 1;
        }
      }
    } catch (error) {
      deleteError = error;
    } finally {
      wasCancelled = progress.value.cancelRequested;
      await _rescanAfterFileOperation();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      progress.dispose();
    }

    if (deleteError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除できませんでした: $deleteError')),
        );
      }
      return;
    }

    _clearSelection();
    if (mounted) {
      final suffix = [
        if (successCount > 0) '$successCount件完了',
        if (failureCount > 0) '$failureCount件失敗',
      ].join(' / ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasCancelled
                ? '削除をキャンセルしました${suffix.isEmpty ? '' : '（$suffix）'}'
                : '削除しました${suffix.isEmpty ? '' : '（$suffix）'}',
          ),
        ),
      );
    }
  }

  Future<void> _requestPermission() async {
    await ref.read(mediaPermissionAdapterProvider).requestPermission();
    ref.invalidate(mediaPermissionProvider);
    await ref.read(scanVideosUseCaseProvider).call();
  }

  Future<void> _rescanAfterFileOperation() async {
    try {
      await ref.read(scanVideosUseCaseProvider).call();
    } catch (_) {
      // The visible operation result is more useful than a secondary rescan error.
    }
  }

  Future<void> _requestAdditionalVideoAccess() async {
    await ref
        .read(mediaPermissionAdapterProvider)
        .requestAdditionalVideoAccess();
    ref.invalidate(mediaPermissionProvider);
    await ref.read(scanVideosUseCaseProvider).call();
  }

  Future<void> _openAppSettings() async {
    await ref.read(mediaPermissionAdapterProvider).openAppSettings();
  }

  Future<void> _restoreQueryPreferences() async {
    final query = await ref.read(videoQueryPreferencesStoreProvider).load();
    if (!mounted) {
      return;
    }

    ref.read(videoQueryProvider.notifier).state = query;
  }
}

class _BatchProgress {
  const _BatchProgress({
    required this.label,
    required this.current,
    required this.total,
    this.cancelRequested = false,
  });

  final String label;
  final int current;
  final int total;
  final bool cancelRequested;

  _BatchProgress copyWith({
    String? label,
    int? current,
    int? total,
    bool? cancelRequested,
  }) {
    return _BatchProgress(
      label: label ?? this.label,
      current: current ?? this.current,
      total: total ?? this.total,
      cancelRequested: cancelRequested ?? this.cancelRequested,
    );
  }
}

class _LifecycleObserver extends WidgetsBindingObserver {
  _LifecycleObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class _LimitedPermissionBanner extends StatelessWidget {
  const _LimitedPermissionBanner({
    required this.onRequestAdditionalAccess,
    required this.onOpenSettings,
  });

  final VoidCallback onRequestAdditionalAccess;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.video_settings, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '選択した動画のみ表示しています。必要な動画が見つからない場合はアクセス対象を追加してください。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 4,
              children: [
                TextButton(
                  onPressed: onRequestAdditionalAccess,
                  child: const Text('追加選択'),
                ),
                TextButton(
                  onPressed: onOpenSettings,
                  child: const Text('設定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRequiredPanel extends StatelessWidget {
  const _PermissionRequiredPanel({
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '動画へのアクセス許可が必要です',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '端末内の動画を一覧表示するため、メディアアクセス権限を許可してください。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRequestPermission,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('権限を許可'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('設定を開く'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryToolbar extends ConsumerWidget {
  const _LibraryToolbar({required this.query});

  final VideoQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchHistory = ref.watch(searchHistoryProvider).valueOrNull ?? [];
    final settings = ref.watch(appSettingsProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: '動画名またはフォルダ名で検索',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              final search = ref.read(searchVideosUseCaseProvider);
              ref.read(videoQueryProvider.notifier).state =
                  search(query, value);
            },
            onSubmitted: (value) async {
              await ref.read(videoRepositoryProvider).addSearchHistory(value);
              ref.invalidate(searchHistoryProvider);
            },
          ),
          if (searchHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final keyword in searchHistory)
                    ActionChip(
                      avatar: const Icon(Icons.history, size: 18),
                      label: Text(keyword),
                      onPressed: () {
                        final search = ref.read(searchVideosUseCaseProvider);
                        ref.read(videoQueryProvider.notifier).state =
                            search(query, keyword);
                      },
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          DropdownButtonFormField<VideoSearchTarget>(
            value: query.searchTarget,
            decoration: const InputDecoration(
              labelText: '検索対象',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: VideoSearchTarget.all,
                child: Text('すべて'),
              ),
              DropdownMenuItem(
                value: VideoSearchTarget.title,
                child: Text('動画名'),
              ),
              DropdownMenuItem(
                value: VideoSearchTarget.folder,
                child: Text('フォルダ名'),
              ),
            ],
            onChanged: (target) {
              if (target == null) {
                return;
              }

              final nextQuery = query.copyWith(searchTarget: target);
              ref.read(videoQueryProvider.notifier).state = nextQuery;
              unawaited(
                ref.read(videoQueryPreferencesStoreProvider).save(nextQuery),
              );
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<VideoFilter>(
            value: query.filter,
            decoration: const InputDecoration(
              labelText: 'フィルタ',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: VideoFilter.all, child: Text('すべて')),
              DropdownMenuItem(value: VideoFilter.hdr, child: Text('HDR')),
              DropdownMenuItem(
                  value: VideoFilter.video360, child: Text('360度')),
              DropdownMenuItem(
                value: VideoFilter.slowMotion,
                child: Text('スローモーション'),
              ),
              DropdownMenuItem(
                value: VideoFilter.hyperlapse,
                child: Text('Hyperlapse'),
              ),
              DropdownMenuItem(value: VideoFilter.drm, child: Text('DRM')),
              DropdownMenuItem(
                  value: VideoFilter.largeSize, child: Text('サイズ大')),
              DropdownMenuItem(
                value: VideoFilter.recentlyAdded,
                child: Text('最近追加'),
              ),
              DropdownMenuItem(
                value: VideoFilter.recentlyPlayed,
                child: Text('最近再生'),
              ),
              DropdownMenuItem(
                value: VideoFilter.favorite,
                child: Text('お気に入り'),
              ),
              DropdownMenuItem(
                value: VideoFilter.privateVideos,
                child: Text('非表示'),
              ),
              DropdownMenuItem(
                value: VideoFilter.unplayable,
                child: Text('再生不可'),
              ),
            ],
            onChanged: (filter) async {
              if (filter == null) {
                return;
              }

              if (filter == VideoFilter.privateVideos) {
                final authenticated = await _authenticatePrivateAccess(
                  context,
                  ref,
                  settings,
                );
                if (!authenticated) {
                  return;
                }
              }

              final nextQuery = query.copyWith(filter: filter);
              ref.read(videoQueryProvider.notifier).state = nextQuery;
              await ref
                  .read(videoQueryPreferencesStoreProvider)
                  .save(nextQuery);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<VideoSortKey>(
                  value: query.sortKey,
                  decoration: const InputDecoration(
                    labelText: '並び替え',
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
                  onChanged: (sortKey) {
                    if (sortKey == null) {
                      return;
                    }

                    final nextQuery = query.copyWith(sortKey: sortKey);
                    ref.read(videoQueryProvider.notifier).state = nextQuery;
                    unawaited(
                      ref
                          .read(videoQueryPreferencesStoreProvider)
                          .save(nextQuery),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: query.sortOrder == SortOrder.descending ? '降順' : '昇順',
                onPressed: () {
                  final nextOrder = query.sortOrder == SortOrder.descending
                      ? SortOrder.ascending
                      : SortOrder.descending;
                  final nextQuery = query.copyWith(sortOrder: nextOrder);
                  ref.read(videoQueryProvider.notifier).state = nextQuery;
                  unawaited(
                    ref
                        .read(videoQueryPreferencesStoreProvider)
                        .save(nextQuery),
                  );
                },
                icon: Icon(
                  query.sortOrder == SortOrder.descending
                      ? Icons.south
                      : Icons.north,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _authenticatePrivateAccess(
    BuildContext context,
    WidgetRef ref,
    AppSettings? settings,
  ) async {
    final AppSettings? currentSettings =
        settings ?? await ref.read(appSettingsProvider.future);
    if (currentSettings == null) {
      return false;
    }

    if (!context.mounted) {
      return false;
    }

    return authenticatePrivateAccess(
      context,
      ref,
      currentSettings,
      confirmLabel: '開く',
    );
  }
}

class VideoGrid extends StatefulWidget {
  const VideoGrid({
    required this.videos,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.enableInstantPlayer,
    required this.viewMode,
    this.emptyLabel = '動画が見つかりません',
    this.selectedVideoIds = const {},
    this.selectionMode = false,
    this.onToggleSelection,
    this.onStartSelection,
    super.key,
  });

  final List<Video> videos;
  final bool showPlaybackProgress;
  final bool showTags;
  final bool enableInstantPlayer;
  final LibraryViewMode viewMode;
  final String emptyLabel;
  final Set<String> selectedVideoIds;
  final bool selectionMode;
  final ValueChanged<String>? onToggleSelection;
  final ValueChanged<String>? onStartSelection;

  @override
  State<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<VideoGrid> {
  @override
  void initState() {
    super.initState();
    _prefetchInitialThumbnails();
  }

  @override
  void didUpdateWidget(covariant VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videos != widget.videos ||
        oldWidget.viewMode != widget.viewMode) {
      _prefetchInitialThumbnails();
    }
  }

  void _prefetchInitialThumbnails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      VideoThumbnailLoader.prefetch(widget.videos, limit: 18);
    });
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.videos;
    if (videos.isEmpty) {
      return Center(child: Text(widget.emptyLabel));
    }

    if (widget.viewMode == LibraryViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final video = videos[index];

          return SizedBox(
            height: 260,
            child: VideoTileNavigation(
              video: video,
              showPlaybackProgress: widget.showPlaybackProgress,
              showTags: widget.showTags,
              enableInstantPlayer: widget.enableInstantPlayer,
              selected: widget.selectedVideoIds.contains(video.id),
              selectionMode: widget.selectionMode,
              onToggleSelection: widget.onToggleSelection,
              onStartSelection: widget.onStartSelection,
            ),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 260,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];

        return VideoTileNavigation(
          video: video,
          showPlaybackProgress: widget.showPlaybackProgress,
          showTags: widget.showTags,
          enableInstantPlayer: widget.enableInstantPlayer,
          selected: widget.selectedVideoIds.contains(video.id),
          selectionMode: widget.selectionMode,
          onToggleSelection: widget.onToggleSelection,
          onStartSelection: widget.onStartSelection,
        );
      },
    );
  }
}

class VideoTileNavigation extends StatelessWidget {
  const VideoTileNavigation({
    required this.video,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.enableInstantPlayer,
    this.selected = false,
    this.selectionMode = false,
    this.onToggleSelection,
    this.onStartSelection,
    super.key,
  });

  final Video video;
  final bool showPlaybackProgress;
  final bool showTags;
  final bool enableInstantPlayer;
  final bool selected;
  final bool selectionMode;
  final ValueChanged<String>? onToggleSelection;
  final ValueChanged<String>? onStartSelection;

  @override
  Widget build(BuildContext context) {
    void openDetails() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VideoDetailScreen(videoId: video.id),
        ),
      );
    }

    void openPreview() {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => QuickPreviewSheet(video: video),
      );
    }

    return VideoTile(
      video: video,
      showPlaybackProgress: showPlaybackProgress,
      showTags: showTags,
      onTap: () {
        if (selectionMode) {
          onToggleSelection?.call(video.id);
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FullScreenPlayerScreen(videoId: video.id),
          ),
        );
      },
      onLongPress: onStartSelection == null
          ? openDetails
          : () => onStartSelection?.call(video.id),
      onPreview: selectionMode || !enableInstantPlayer || !video.isPlayable
          ? null
          : openPreview,
      onDetails: openDetails,
      selected: selected,
    );
  }
}
