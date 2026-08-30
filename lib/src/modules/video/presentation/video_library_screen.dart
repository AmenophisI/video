import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/utils/duration_format.dart';
import '../../../shared/utils/file_name_utils.dart';
import '../../folder/presentation/folder_list_screen.dart';
import '../../media_access/domain/media_permission.dart';
import '../../playback/presentation/full_screen_player_screen.dart';
import '../../playback/presentation/quick_preview_sheet.dart';
import '../../playback/presentation/widgets/native_video_player_view.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_screen.dart';
import '../application/video_providers.dart';
import '../domain/video.dart';
import '../domain/video_query.dart';
import 'video_detail_screen.dart';
import 'relative_path_picker_screen.dart';
import 'widgets/file_conflict_dialog.dart';
import 'widgets/playback_progress_bar.dart';
import 'widgets/video_thumbnail.dart';
import 'widgets/video_tile.dart';

class VideoLibraryScreen extends ConsumerStatefulWidget {
  const VideoLibraryScreen({super.key});

  @override
  ConsumerState<VideoLibraryScreen> createState() => _VideoLibraryScreenState();
}

class _VideoLibraryScreenState extends ConsumerState<VideoLibraryScreen> {
  final Set<String> _selectedVideoIds = {};
  final NativeVideoPlayerController _instantPlayerController =
      NativeVideoPlayerController();
  late final _LifecycleObserver _lifecycleObserver;
  late final PageController _tabController;
  final SharedPreferencesAsync _tabPreferences = SharedPreferencesAsync();
  StreamSubscription<void>? _mediaStoreSubscription;
  int _selectedTabIndex = 0;
  bool _selectionModeActive = false;
  String? _instantVideoId;

  bool get _isSelectionMode => _selectionModeActive;

  @override
  void initState() {
    super.initState();
    _tabController = PageController();
    Future.microtask(_restoreQueryPreferences);
    Future.microtask(_restoreLastTabIndex);
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
    _tabController.dispose();
    _instantPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VideoQuery>(videoQueryProvider, (previous, next) {
      if (previous == null || _isSameQuery(previous, next)) {
        return;
      }

      if (_selectedVideoIds.isNotEmpty && mounted) {
        setState(() {
          _selectionModeActive = false;
          _selectedVideoIds.clear();
        });
      }
    });

    final videosAsync = ref.watch(videoLibraryProvider);
    final permissionAsync = ref.watch(mediaPermissionProvider);
    final query = ref.watch(videoQueryProvider);
    final settings = ref.watch(appSettingsProvider).maybeWhen(
          data: (settings) => settings,
          orElse: () => null,
        );

    final isVideoTab = _selectedTabIndex == 0;

    return PopScope<void>(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: isVideoTab && _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  tooltip: '選択解除',
                  onPressed: _clearSelection,
                  icon: const Icon(Icons.close),
                ),
                title: Text(
                  _selectedVideoIds.isEmpty
                      ? '動画を選択'
                      : '${_selectedVideoIds.length}件選択',
                ),
                actions: [
                  TextButton(
                    onPressed: _selectAllVisible,
                    child: const Text('全て'),
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _tabController,
                onPageChanged: _handleTabSwipe,
                children: [
                  Column(
                    children: [
                      _LibraryToolbar(
                        query: query,
                        onStartSelection: _enterSelectionMode,
                      ),
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
                                  if (settings?.enableInstantPlayer == true &&
                                      _videoWithId(videos, _instantVideoId) !=
                                          null)
                                    _LibraryInstantPlayerPanel(
                                      video: _videoWithId(
                                        videos,
                                        _instantVideoId,
                                      )!,
                                      controller: _instantPlayerController,
                                      onPrevious: () =>
                                          _moveInstantSelection(videos, -1),
                                      onNext: () =>
                                          _moveInstantSelection(videos, 1),
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
                                          LibraryViewMode.list,
                                      selectedVideoIds: _isSelectionMode
                                          ? _selectedVideoIds
                                          : _instantVideoId == null
                                              ? const <String>{}
                                              : {_instantVideoId!},
                                      selectionMode: _isSelectionMode,
                                      onToggleSelection: _toggleSelection,
                                      onStartSelection: _startSelection,
                                      onPreviewVideo:
                                          settings?.enableInstantPlayer == true
                                              ? (video) => setState(() {
                                                    _instantVideoId = video.id;
                                                  })
                                              : null,
                                      emptyState:
                                          _buildLibraryEmptyState(query),
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
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _isSelectionMode
            ? _SelectionActionBar(
                enabled: _selectedVideoIds.isNotEmpty,
                onShare: _shareSelected,
                onDelete: _deleteSelected,
                onMore: _showSelectionMoreMenu,
              )
            : _SamsungBottomTabs(
                selectedIndex: _selectedTabIndex,
                onSelected: _handleTabSelected,
              ),
      ),
    );
  }

  Future<void> _restoreLastTabIndex() async {
    final index =
        (await _tabPreferences.getInt(_lastTabIndexKey) ?? 0).clamp(0, 1);

    if (!mounted || index == _selectedTabIndex) {
      return;
    }

    setState(() {
      _selectedTabIndex = index;
      if (index != 0) {
        _selectedVideoIds.clear();
      }
    });
    if (_tabController.hasClients) {
      _tabController.jumpToPage(index);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _tabController.hasClients) {
          _tabController.jumpToPage(index);
        }
      });
    }
  }

  void _handleTabSelected(int index) {
    if (index == _selectedTabIndex) {
      return;
    }

    if (!_tabController.hasClients) {
      _setSelectedTab(index);
      return;
    }

    unawaited(
      _tabController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _handleTabSwipe(int index) {
    _setSelectedTab(index);
  }

  void _setSelectedTab(int index) {
    if (index == _selectedTabIndex) {
      return;
    }

    setState(() {
      _selectedTabIndex = index;
      if (index != 0) {
        _selectedVideoIds.clear();
      }
    });

    unawaited(_persistSelectedTab(index));
  }

  Future<void> _persistSelectedTab(int index) async {
    await _tabPreferences.setInt(_lastTabIndexKey, index);
  }

  void _startSelection(String videoId) {
    setState(() {
      _selectionModeActive = true;
      _selectedVideoIds.add(videoId);
    });
  }

  void _enterSelectionMode() {
    setState(() {
      _selectionModeActive = true;
      _selectedVideoIds.clear();
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
    setState(() {
      _selectionModeActive = false;
      _selectedVideoIds.clear();
    });
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('共有できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _showSelectionMoreMenu() async {
    if (_selectedVideoIds.isEmpty) {
      return;
    }

    final screenSize = MediaQuery.sizeOf(context);
    final action = await showMenu<_SelectionMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        screenSize.width - 260,
        screenSize.height - 330,
        16,
        88,
      ),
      items: [
        const PopupMenuItem(
          value: _SelectionMenuAction.editor,
          child: Text('エディター'),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.copy,
          child: Text('コピー'),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.move,
          child: Text('移動'),
        ),
        PopupMenuItem(
          value: _SelectionMenuAction.rename,
          enabled: _selectedVideoIds.length == 1,
          child: const Text('名前変更'),
        ),
        PopupMenuItem(
          value: _SelectionMenuAction.play,
          enabled: _selectedVideoIds.length == 1,
          child: const Text('再生'),
        ),
        const PopupMenuItem(
          value: _SelectionMenuAction.secureFolder,
          child: Text('セキュリティフォルダに移動'),
        ),
      ],
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _SelectionMenuAction.editor:
        await _openSelectedInEditor();
      case _SelectionMenuAction.copy:
        await _moveOrCopySelected(isMove: false);
      case _SelectionMenuAction.move:
        await _moveOrCopySelected(isMove: true);
      case _SelectionMenuAction.rename:
        await _renameSelectedVideo();
      case _SelectionMenuAction.play:
        await _playSelectedVideo();
      case _SelectionMenuAction.secureFolder:
        await _moveSelectedToSecureFolder();
    }
  }

  Future<void> _moveSelectedToSecureFolder() async {
    try {
      await ref.read(videoRepositoryProvider).moveToSecureFolder(
            _selectedVideoIds.toList(growable: false),
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('セキュリティフォルダを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _openSelectedInEditor() async {
    final id = _selectedVideoIds.firstOrNull;
    if (id == null) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).openVideoInEditor(id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エディターを開けませんでした: $error')),
        );
      }
    }
  }

  Future<void> _playSelectedVideo() async {
    final id = _selectedVideoIds.firstOrNull;
    if (id == null) {
      return;
    }

    final videos =
        ref.read(videoLibraryProvider).valueOrNull ?? const <Video>[];
    final playlistIds = videos.map((video) => video.id).toList(growable: false);
    final initialIndex = playlistIds.indexOf(id);
    _clearSelection();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenPlayerScreen(
          videoId: id,
          playlistVideoIds: playlistIds,
          playlistInitialIndex: initialIndex < 0 ? 0 : initialIndex,
        ),
      ),
    );
  }

  Future<void> _renameSelectedVideo() async {
    final id = _selectedVideoIds.firstOrNull;
    if (id == null) {
      return;
    }

    final video = await ref.read(videoRepositoryProvider).getVideo(id);
    if (!mounted || video == null) {
      return;
    }

    final controller = TextEditingController(text: video.displayName);
    String currentName = video.displayName;
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('動画の名前を変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            onChanged: (value) {
              setDialogState(() {
                currentName = value.trim();
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: currentName.isEmpty || currentName == video.displayName
                  ? null
                  : () => Navigator.of(context).pop(currentName),
              child: const Text('名前変更'),
            ),
          ],
        ),
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      controller.dispose,
    );

    if (newName == null || !mounted) {
      return;
    }

    try {
      await ref.read(videoRepositoryProvider).renameVideo(
            videoId: id,
            displayName: newName,
          );
      await _rescanAfterFileOperation();
      _clearSelection();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('名前変更できませんでした: $error')),
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

    final relativePath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RelativePathPickerScreen(
          title: isMove ? '移動' : 'コピー',
          folderOptions: knownVideos.map((video) => video.relativePath),
        ),
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

  VideoGridEmptyState _buildLibraryEmptyState(VideoQuery query) {
    if (_hasActiveLibraryCondition(query)) {
      return VideoGridEmptyState(
        icon: Icons.search_off,
        title: '検索結果がありません',
        description: '検索キーワードまたはフィルタを変更してください。',
        actionIcon: Icons.filter_alt_off,
        actionLabel: '条件をクリア',
        onAction: () {
          final nextQuery = query.copyWith(
            searchText: '',
            filter: VideoFilter.all,
          );
          ref.read(videoQueryProvider.notifier).state = nextQuery;
          unawaited(
            ref.read(videoQueryPreferencesStoreProvider).save(nextQuery),
          );
        },
      );
    }

    return VideoGridEmptyState(
      icon: Icons.video_library_outlined,
      title: '動画が見つかりません',
      description: '端末内の動画を再スキャンしてください。',
      actionIcon: Icons.refresh,
      actionLabel: '再スキャン',
      onAction: () => ref.read(scanVideosUseCaseProvider).call(),
    );
  }

  bool _hasActiveLibraryCondition(VideoQuery query) {
    return query.searchText.trim().isNotEmpty ||
        query.filter != VideoFilter.all;
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

  Video? _videoWithId(List<Video> videos, String? id) {
    if (id == null) return null;
    for (final video in videos) {
      if (video.id == id) return video;
    }
    return null;
  }

  void _moveInstantSelection(List<Video> videos, int offset) {
    if (videos.isEmpty) return;
    final current = videos.indexWhere((video) => video.id == _instantVideoId);
    final next =
        (current < 0 ? 0 : current + offset).clamp(0, videos.length - 1);
    setState(() {
      _instantVideoId = videos[next].id;
    });
  }
}

const String _lastTabIndexKey = 'settings.lastTabIndex';

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

class _LibraryInstantPlayerPanel extends StatelessWidget {
  const _LibraryInstantPlayerPanel({
    required this.video,
    required this.controller,
    required this.onPrevious,
    required this.onNext,
  });

  final Video video;
  final NativeVideoPlayerController controller;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = video.width != null &&
            video.height != null &&
            video.width! > 0 &&
            video.height! > 0
        ? video.width! / video.height!
        : 16 / 9;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2F8CFF), width: 3)),
      ),
      child: SizedBox(
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: NativeVideoPlayerView(
                    key: ValueKey('library-instant-${video.id}'),
                    controller: controller,
                    uri: video.uri,
                    initialPosition: video.lastPlayedPosition ?? Duration.zero,
                    subtitleUri: video.subtitleUri,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                tooltip: '前の動画',
                onPressed: onPrevious,
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton.filledTonal(
                tooltip: '次の動画',
                onPressed: onNext,
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SamsungBottomTabs extends StatelessWidget {
  const _SamsungBottomTabs({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _SamsungBottomTab(
                label: '動画',
                selected: selectedIndex == 0,
                onTap: () => onSelected(0),
              ),
              _SamsungBottomTab(
                label: 'フォルダ',
                selected: selectedIndex == 1,
                onTap: () => onSelected(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SamsungBottomTab extends StatelessWidget {
  const _SamsungBottomTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: selected ? Colors.white : Colors.white60,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 72 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.enabled,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
  });

  final bool enabled;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SelectionAction(
                label: '共有',
                icon: Icons.ios_share,
                onPressed: enabled ? onShare : null,
              ),
              _SelectionAction(
                label: '削除',
                icon: Icons.delete_outline,
                onPressed: enabled ? onDelete : null,
              ),
              _SelectionAction(
                label: 'その他',
                icon: Icons.more_vert,
                onPressed: enabled ? onMore : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionAction extends StatelessWidget {
  const _SelectionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
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

class _LibraryToolbar extends ConsumerStatefulWidget {
  const _LibraryToolbar({
    required this.query,
    required this.onStartSelection,
  });

  final VideoQuery query;
  final VoidCallback onStartSelection;

  @override
  ConsumerState<_LibraryToolbar> createState() => _LibraryToolbarState();
}

class _LibraryToolbarState extends ConsumerState<_LibraryToolbar> {
  late final TextEditingController _searchController;
  late bool _searchMode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query.searchText);
    _searchMode = widget.query.searchText.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant _LibraryToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query.searchText != widget.query.searchText &&
        _searchController.text != widget.query.searchText) {
      _searchController.text = widget.query.searchText;
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchHistory = ref.watch(searchHistoryProvider).valueOrNull ?? [];
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final query = widget.query;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope<void>(
      canPop: !_searchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searchMode) _closeSearch();
      },
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 6, 13, 8),
          child: Column(
            children: [
              if (_searchMode)
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      tooltip: '戻る',
                      onPressed: _closeSearch,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    hintText: '検索',
                    suffixIconConstraints: const BoxConstraints(minWidth: 96),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            tooltip: '消去',
                            onPressed: () {
                              _searchController.clear();
                              _updateSearch('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.close),
                          ),
                        IconButton(
                          tooltip: '音声検索',
                          onPressed: _startVoiceSearch,
                          icon: const Icon(Icons.mic_none),
                        ),
                      ],
                    ),
                  ),
                  onChanged: (value) {
                    _updateSearch(value);
                    setState(() {});
                  },
                  onSubmitted: (value) async {
                    await ref
                        .read(videoRepositoryProvider)
                        .addSearchHistory(value);
                    ref.invalidate(searchHistoryProvider);
                  },
                ),
              if (_searchMode && searchHistory.isNotEmpty) ...[
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
                            final search =
                                ref.read(searchVideosUseCaseProvider);
                            ref.read(videoQueryProvider.notifier).state =
                                search(query, keyword);
                          },
                        ),
                    ],
                  ),
                ),
              ],
              if (!_searchMode)
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      tooltip: _nextViewModeLabel(settings?.viewMode),
                      color: colorScheme.primary,
                      onPressed: settings == null
                          ? null
                          : () {
                              final nextViewMode =
                                  _nextViewMode(settings.viewMode);
                              unawaited(
                                ref.read(updateSettingsUseCaseProvider).call(
                                    settings.copyWith(viewMode: nextViewMode)),
                              );
                            },
                      icon: Icon(_viewModeIcon(settings?.viewMode)),
                    ),
                    IconButton(
                      tooltip: '検索',
                      onPressed: () {
                        setState(() {
                          _searchMode = true;
                        });
                      },
                      icon: const Icon(Icons.search),
                    ),
                    PopupMenuButton<Object>(
                      tooltip: 'その他',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value is _LibraryMenuAction) {
                          switch (value) {
                            case _LibraryMenuAction.edit:
                              widget.onStartSelection();
                            case _LibraryMenuAction.sort:
                              await _showSortDialog(query);
                            case _LibraryMenuAction.toggleInstantPlayer:
                              if (settings != null) {
                                await ref
                                    .read(updateSettingsUseCaseProvider)
                                    .call(
                                      settings.copyWith(
                                        enableInstantPlayer:
                                            !settings.enableInstantPlayer,
                                      ),
                                    );
                              }
                            case _LibraryMenuAction.about:
                              if (context.mounted) {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              }
                            case _LibraryMenuAction.contact:
                              if (context.mounted) {
                                await showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('お問い合わせ'),
                                    content: const Text(
                                      'アプリに関するお問い合わせは、配布元のサポート窓口をご利用ください。',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('閉じる'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                          }
                          return;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: _LibraryMenuAction.edit,
                          child: Text('編集'),
                        ),
                        const PopupMenuItem(
                          value: _LibraryMenuAction.sort,
                          child: Text('並べ替え'),
                        ),
                        PopupMenuItem(
                          value: _LibraryMenuAction.toggleInstantPlayer,
                          child: Text(
                            settings?.enableInstantPlayer == true
                                ? 'インスタントプレーヤーOFF'
                                : 'インスタントプレーヤーON',
                          ),
                        ),
                        const PopupMenuItem(
                          value: _LibraryMenuAction.about,
                          child: Text('ビデオについて'),
                        ),
                        const PopupMenuItem(
                          value: _LibraryMenuAction.contact,
                          child: Text('お問い合わせ'),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  LibraryViewMode _nextViewMode(LibraryViewMode mode) {
    return switch (mode) {
      LibraryViewMode.list => LibraryViewMode.grid,
      LibraryViewMode.grid => LibraryViewMode.enlarged,
      LibraryViewMode.enlarged => LibraryViewMode.list,
    };
  }

  String _nextViewModeLabel(LibraryViewMode? mode) {
    return switch (mode ?? LibraryViewMode.list) {
      LibraryViewMode.list => 'グリッド表示',
      LibraryViewMode.grid => '拡大表示',
      LibraryViewMode.enlarged => 'リスト表示',
    };
  }

  IconData _viewModeIcon(LibraryViewMode? mode) {
    return switch (mode ?? LibraryViewMode.list) {
      LibraryViewMode.list => Icons.grid_view,
      LibraryViewMode.grid => Icons.view_agenda_outlined,
      LibraryViewMode.enlarged => Icons.view_list,
    };
  }

  void _updateSearch(String value) {
    final search = ref.read(searchVideosUseCaseProvider);
    ref.read(videoQueryProvider.notifier).state = search(widget.query, value);
  }

  void _closeSearch() {
    _searchController.clear();
    _updateSearch('');
    setState(() {
      _searchMode = false;
    });
  }

  Future<void> _startVoiceSearch() async {
    try {
      const channel = MethodChannel('video_player/system');
      final text = await channel.invokeMethod<String>('startVoiceSearch');
      if (text == null || text.trim().isEmpty || !mounted) return;
      _searchController.text = text.trim();
      _searchController.selection = TextSelection.collapsed(
        offset: _searchController.text.length,
      );
      _updateSearch(_searchController.text);
      await ref
          .read(videoRepositoryProvider)
          .addSearchHistory(_searchController.text);
      ref.invalidate(searchHistoryProvider);
      setState(() {});
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('音声検索を開始できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _showSortDialog(VideoQuery query) async {
    var sortKey = query.sortKey == VideoSortKey.title
        ? VideoSortKey.title
        : VideoSortKey.modifiedAt;
    var sortOrder = query.sortOrder;
    final result = await showModalBottomSheet<VideoQuery>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '並べ替え',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                RadioListTile<VideoSortKey>(
                  value: VideoSortKey.modifiedAt,
                  groupValue: sortKey,
                  title: const Text('日時'),
                  onChanged: (value) => setSheetState(() => sortKey = value!),
                ),
                RadioListTile<VideoSortKey>(
                  value: VideoSortKey.title,
                  groupValue: sortKey,
                  title: const Text('タイトル'),
                  onChanged: (value) => setSheetState(() => sortKey = value!),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text('順序'),
                ),
                RadioListTile<SortOrder>(
                  value: SortOrder.ascending,
                  groupValue: sortOrder,
                  title: const Text('昇順'),
                  onChanged: (value) => setSheetState(() => sortOrder = value!),
                ),
                RadioListTile<SortOrder>(
                  value: SortOrder.descending,
                  groupValue: sortOrder,
                  title: const Text('降順'),
                  onChanged: (value) => setSheetState(() => sortOrder = value!),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(
                        query.copyWith(sortKey: sortKey, sortOrder: sortOrder),
                      ),
                      child: const Text('完了'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == null) return;
    ref.read(videoQueryProvider.notifier).state = result;
    await ref.read(videoQueryPreferencesStoreProvider).save(result);
    if (mounted) {
      setState(() {});
    }
  }
}

class VideoGrid extends StatefulWidget {
  const VideoGrid({
    required this.videos,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.enableInstantPlayer,
    required this.viewMode,
    this.emptyState,
    this.emptyLabel = '動画が見つかりません',
    this.selectedVideoIds = const {},
    this.selectionMode = false,
    this.onToggleSelection,
    this.onStartSelection,
    this.onOpenVideo,
    this.onPreviewVideo,
    super.key,
  });

  final List<Video> videos;
  final bool showPlaybackProgress;
  final bool showTags;
  final bool enableInstantPlayer;
  final LibraryViewMode viewMode;
  final VideoGridEmptyState? emptyState;
  final String emptyLabel;
  final Set<String> selectedVideoIds;
  final bool selectionMode;
  final ValueChanged<String>? onToggleSelection;
  final ValueChanged<String>? onStartSelection;
  final ValueChanged<Video>? onOpenVideo;
  final ValueChanged<Video>? onPreviewVideo;

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
      return VideoGridEmptyPanel(
        state: widget.emptyState ??
            VideoGridEmptyState(
              icon: Icons.video_library_outlined,
              title: widget.emptyLabel,
            ),
      );
    }

    if (widget.viewMode == LibraryViewMode.list) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final video = videos[index];

          return VideoListRowNavigation(
            video: video,
            showPlaybackProgress: widget.showPlaybackProgress,
            showTags: widget.showTags,
            enableInstantPlayer: widget.enableInstantPlayer,
            selected: widget.selectedVideoIds.contains(video.id),
            selectionMode: widget.selectionMode,
            onToggleSelection: widget.onToggleSelection,
            onStartSelection: widget.onStartSelection,
            onOpenVideo: widget.onOpenVideo,
            onPreviewVideo: widget.onPreviewVideo,
          );
        },
      );
    }

    final isEnlarged = widget.viewMode == LibraryViewMode.enlarged;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isEnlarged ? 1 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isEnlarged ? 1.32 : 0.68,
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
          onOpenVideo: widget.onOpenVideo,
          onPreviewVideo: widget.onPreviewVideo,
        );
      },
    );
  }
}

class VideoGridEmptyState {
  const VideoGridEmptyState({
    required this.icon,
    required this.title,
    this.description,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final IconData? actionIcon;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class VideoGridEmptyPanel extends StatelessWidget {
  const VideoGridEmptyPanel({required this.state, super.key});

  final VideoGridEmptyState state;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.icon,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              state.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (state.description != null) ...[
              const SizedBox(height: 8),
              Text(
                state.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (state.actionLabel != null && state.onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: state.onAction,
                icon: Icon(state.actionIcon ?? Icons.refresh),
                label: Text(state.actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VideoListRowNavigation extends StatelessWidget {
  const VideoListRowNavigation({
    required this.video,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.enableInstantPlayer,
    this.selected = false,
    this.selectionMode = false,
    this.onToggleSelection,
    this.onStartSelection,
    this.onOpenVideo,
    this.onPreviewVideo,
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
  final ValueChanged<Video>? onOpenVideo;
  final ValueChanged<Video>? onPreviewVideo;

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
      if (onPreviewVideo != null) {
        onPreviewVideo!(video);
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => QuickPreviewSheet(video: video),
      );
    }

    void openActionMenu() {
      onStartSelection?.call(video.id);
    }

    return VideoListRow(
      video: video,
      showPlaybackProgress: showPlaybackProgress,
      showTags: showTags,
      selected: selected,
      onTap: () {
        if (selectionMode) {
          onToggleSelection?.call(video.id);
          return;
        }

        if (onOpenVideo != null) {
          onOpenVideo!(video);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FullScreenPlayerScreen(videoId: video.id),
            ),
          );
        }
      },
      onLongPress: onStartSelection == null ? openDetails : openActionMenu,
      onPreview: selectionMode || !enableInstantPlayer || !video.isPlayable
          ? null
          : openPreview,
      onDetails: openDetails,
    );
  }
}

class VideoListRow extends StatelessWidget {
  const VideoListRow({
    required this.video,
    required this.showPlaybackProgress,
    required this.showTags,
    required this.onTap,
    this.onLongPress,
    this.onPreview,
    this.onDetails,
    this.selected = false,
    super.key,
  });

  final Video video;
  final bool showPlaybackProgress;
  final bool showTags;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPreview;
  final VoidCallback? onDetails;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final progress = video.playbackProgress;
    final showProgress = showPlaybackProgress && video.hasPlaybackProgress;
    final dateLabel = video.modifiedAt != null
        ? '更新 ${formatDate(video.modifiedAt)}'
        : video.createdAt != null
            ? '作成 ${formatDate(video.createdAt)}'
            : null;
    final sizeLabel = formatFileSize(video.sizeBytes);
    final metadata = [
      video.folderName,
      if (dateLabel != null) dateLabel,
      if (sizeLabel != '--') sizeLabel,
    ].join(' ・ ');
    final semanticParts = [
      video.displayName,
      '再生時間 ${formatDuration(video.duration)}',
      'フォルダ ${video.folderName}',
      if (dateLabel != null) dateLabel,
      if (sizeLabel != '--') 'サイズ $sizeLabel',
      if (selected) '選択中',
      if (!video.isPlayable) '再生不可',
      if (showProgress) '視聴進捗 ${(progress * 100).round()}パーセント',
      if (showTags && video.tags.isNotEmpty) 'タグ ${video.tags.join('、')}',
    ];

    return Semantics(
      button: true,
      selected: selected,
      label: semanticParts.join('。'),
      onTapHint: selected ? '選択を解除します' : '動画を再生します',
      onLongPressHint: onLongPress == null ? null : '動画を選択します',
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 118,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          VideoThumbnail(video: video),
                          if (onPreview != null)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: _InlinePreviewButton(
                                onPressed: onPreview!,
                              ),
                            ),
                          Positioned(
                            right: 6,
                            bottom: showProgress ? 11 : 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.52),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: Text(
                                  formatDuration(video.duration),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          if (showProgress)
                            Positioned(
                              left: 6,
                              right: 6,
                              bottom: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: PlaybackProgressBar(progress: progress),
                              ),
                            ),
                          if (selected)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.20),
                                ),
                              ),
                            ),
                          if (selected)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (showTags && video.tags.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final tag in video.tags.take(3))
                              Chip(
                                label: Text(tag),
                                labelStyle:
                                    Theme.of(context).textTheme.labelSmall,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    this.onOpenVideo,
    this.onPreviewVideo,
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
  final ValueChanged<Video>? onOpenVideo;
  final ValueChanged<Video>? onPreviewVideo;

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
      if (onPreviewVideo != null) {
        onPreviewVideo!(video);
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: false,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (_) => QuickPreviewSheet(video: video),
      );
    }

    void openActionMenu() {
      onStartSelection?.call(video.id);
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

        if (onOpenVideo != null) {
          onOpenVideo!(video);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FullScreenPlayerScreen(videoId: video.id),
            ),
          );
        }
      },
      onLongPress: onStartSelection == null ? openDetails : openActionMenu,
      onPreview: selectionMode || !enableInstantPlayer || !video.isPlayable
          ? null
          : openPreview,
      onDetails: openDetails,
      selected: selected,
    );
  }
}

enum _SelectionMenuAction {
  editor,
  copy,
  move,
  rename,
  play,
  secureFolder,
}

enum _LibraryMenuAction {
  edit,
  sort,
  toggleInstantPlayer,
  about,
  contact,
}

class _InlinePreviewButton extends StatelessWidget {
  const _InlinePreviewButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onPressed,
        radius: 16,
        containedInkWell: true,
        customBorder: const CircleBorder(),
        child: const SizedBox.square(
          dimension: 24,
          child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
