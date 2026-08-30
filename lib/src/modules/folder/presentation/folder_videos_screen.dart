import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playback/presentation/full_screen_player_screen.dart';
import '../../playback/presentation/widgets/native_video_player_view.dart';
import '../../settings/application/settings_providers.dart';
import '../../settings/domain/app_settings.dart';
import '../../video/application/video_providers.dart';
import '../../video/domain/video.dart';
import '../../video/domain/video_query.dart';
import '../../video/presentation/video_library_screen.dart';
import '../../video/presentation/relative_path_picker_screen.dart';
import '../application/folder_providers.dart';
import '../domain/folder.dart';

class FolderVideosScreen extends ConsumerStatefulWidget {
  const FolderVideosScreen({required this.folder, super.key});

  final Folder folder;

  @override
  ConsumerState<FolderVideosScreen> createState() => _FolderVideosScreenState();
}

class _FolderVideosScreenState extends ConsumerState<FolderVideosScreen> {
  final Set<String> _selectedVideoIds = {};
  final NativeVideoPlayerController _instantPlayerController =
      NativeVideoPlayerController();

  LibraryViewMode _viewMode = LibraryViewMode.list;
  VideoSortKey _sortKey = VideoSortKey.modifiedAt;
  SortOrder _sortOrder = SortOrder.descending;
  String _searchText = '';
  bool _searchMode = false;
  bool _selectionMode = false;
  bool _instantPlayerEnabled = false;
  String? _instantVideoId;

  @override
  void dispose() {
    _instantPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(folderVideosProvider(widget.folder.id));
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final allVideos = videosAsync.valueOrNull ?? const <Video>[];

    return PopScope<void>(
      canPop: !_selectionMode && !_searchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectionMode) {
          _clearSelection();
        } else if (!didPop && _searchMode) {
          setState(() {
            _searchMode = false;
            _searchText = '';
          });
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(allVideos),
        body: videosAsync.when(
          data: (videos) {
            final visibleVideos = _sortVideos(_filterVideos(videos));
            final instantVideo = _findVideo(videos, _instantVideoId);
            return Column(
              children: [
                if (_searchMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: '検索',
                      ),
                      onChanged: (value) => setState(() => _searchText = value),
                    ),
                  ),
                if (_instantPlayerEnabled && instantVideo != null)
                  _InstantPlayerPanel(
                    video: instantVideo,
                    controller: _instantPlayerController,
                    onPrevious: () => _moveInstantSelection(videos, -1),
                    onNext: () => _moveInstantSelection(videos, 1),
                  ),
                Expanded(
                  child: VideoGrid(
                    videos: visibleVideos,
                    showPlaybackProgress:
                        settings?.showPlaybackProgress ?? true,
                    showTags: settings?.showVideoTags ?? true,
                    enableInstantPlayer: _instantPlayerEnabled,
                    viewMode: _viewMode,
                    emptyLabel:
                        _searchText.isEmpty ? 'このフォルダに動画はありません' : '検索結果がありません',
                    selectedVideoIds: _selectionMode
                        ? _selectedVideoIds
                        : _instantVideoId == null
                            ? const <String>{}
                            : {_instantVideoId!},
                    selectionMode: _selectionMode,
                    onToggleSelection: _toggleSelection,
                    onStartSelection: _startSelection,
                    onPreviewVideo: _instantPlayerEnabled
                        ? (video) => setState(() => _instantVideoId = video.id)
                        : null,
                    onOpenVideo: (video) => _openPlayer(video, visibleVideos),
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
        bottomNavigationBar: _selectionMode
            ? _FolderSelectionBar(
                enabled: _selectedVideoIds.isNotEmpty,
                onShare: _shareSelected,
                onDelete: _deleteSelected,
                onMore: _showSelectionMenu,
              )
            : null,
      ),
    );
  }

  AppBar _buildAppBar(List<Video> videos) {
    if (_selectionMode) {
      return AppBar(
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
            onPressed: () => setState(() {
              _selectedVideoIds
                ..clear()
                ..addAll(videos.map((video) => video.id));
            }),
            child: const Text('全て'),
          ),
        ],
      );
    }

    return AppBar(
      title: Text(widget.folder.name),
      actions: [
        IconButton(
          tooltip: _nextViewModeLabel,
          onPressed: () => setState(() => _viewMode = _nextViewMode),
          icon: Icon(_nextViewModeIcon),
        ),
        IconButton(
          tooltip: _searchMode ? '検索を閉じる' : '検索',
          onPressed: () {
            setState(() {
              _searchMode = !_searchMode;
              if (!_searchMode) _searchText = '';
            });
          },
          icon: Icon(_searchMode ? Icons.close : Icons.search),
        ),
        PopupMenuButton<_FolderVideoMenuAction>(
          tooltip: 'その他',
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _FolderVideoMenuAction.edit,
              child: Text('編集'),
            ),
            const PopupMenuItem(
              value: _FolderVideoMenuAction.sort,
              child: Text('並べ替え'),
            ),
            PopupMenuItem(
              value: _FolderVideoMenuAction.instantPlayer,
              child: Text(
                _instantPlayerEnabled ? 'インスタントプレーヤーOFF' : 'インスタントプレーヤーON',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(_FolderVideoMenuAction action) async {
    switch (action) {
      case _FolderVideoMenuAction.edit:
        setState(() {
          _selectionMode = true;
          _selectedVideoIds.clear();
        });
      case _FolderVideoMenuAction.sort:
        await _showSortSheet();
      case _FolderVideoMenuAction.instantPlayer:
        setState(() {
          _instantPlayerEnabled = !_instantPlayerEnabled;
          if (!_instantPlayerEnabled) _instantVideoId = null;
        });
    }
  }

  List<Video> _filterVideos(List<Video> videos) {
    final keyword = _searchText.trim().toLowerCase();
    if (keyword.isEmpty) return videos;
    return videos
        .where((video) => video.displayName.toLowerCase().contains(keyword))
        .toList(growable: false);
  }

  List<Video> _sortVideos(List<Video> videos) {
    final result = [...videos];
    result.sort((a, b) {
      final comparison = _sortKey == VideoSortKey.title
          ? a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase())
          : (a.modifiedAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(b.modifiedAt?.millisecondsSinceEpoch ?? 0);
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return result;
  }

  Future<void> _showSortSheet() async {
    var key = _sortKey;
    var order = _sortOrder;
    final applied = await showModalBottomSheet<bool>(
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
                RadioListTile(
                  value: VideoSortKey.modifiedAt,
                  groupValue: key,
                  title: const Text('日時'),
                  onChanged: (value) => setSheetState(() => key = value!),
                ),
                RadioListTile(
                  value: VideoSortKey.title,
                  groupValue: key,
                  title: const Text('タイトル'),
                  onChanged: (value) => setSheetState(() => key = value!),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('順序'),
                ),
                RadioListTile(
                  value: SortOrder.ascending,
                  groupValue: order,
                  title: const Text('昇順'),
                  onChanged: (value) => setSheetState(() => order = value!),
                ),
                RadioListTile(
                  value: SortOrder.descending,
                  groupValue: order,
                  title: const Text('降順'),
                  onChanged: (value) => setSheetState(() => order = value!),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
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
    if (applied == true && mounted) {
      setState(() {
        _sortKey = key;
        _sortOrder = order;
      });
    }
  }

  void _startSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedVideoIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedVideoIds.remove(id)) _selectedVideoIds.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedVideoIds.clear();
    });
  }

  Future<void> _shareSelected() async {
    if (_selectedVideoIds.isEmpty) return;
    await ref
        .read(videoRepositoryProvider)
        .shareVideos(_selectedVideoIds.toList(growable: false));
  }

  Future<void> _deleteSelected() async {
    if (_selectedVideoIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(videoRepositoryProvider)
        .deleteVideos(_selectedVideoIds.toList(growable: false));
    _clearSelection();
  }

  Future<void> _showSelectionMenu() async {
    if (_selectedVideoIds.isEmpty) return;
    final action = await showModalBottomSheet<_FolderSelectionAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              (_FolderSelectionAction.editor, 'エディター'),
              (_FolderSelectionAction.copy, 'コピー'),
              (_FolderSelectionAction.move, '移動'),
              (_FolderSelectionAction.rename, '名前変更'),
              (_FolderSelectionAction.play, '再生'),
              (_FolderSelectionAction.secureFolder, 'セキュリティフォルダに移動'),
            ])
              ListTile(
                enabled: _selectedVideoIds.length == 1 ||
                    entry.$1 == _FolderSelectionAction.copy ||
                    entry.$1 == _FolderSelectionAction.move ||
                    entry.$1 == _FolderSelectionAction.secureFolder,
                title: Text(entry.$2),
                onTap: () => Navigator.of(context).pop(entry.$1),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _FolderSelectionAction.editor:
        await ref
            .read(videoRepositoryProvider)
            .openVideoInEditor(_selectedVideoIds.first);
      case _FolderSelectionAction.copy:
        await _moveOrCopySelected(isMove: false);
      case _FolderSelectionAction.move:
        await _moveOrCopySelected(isMove: true);
      case _FolderSelectionAction.rename:
        await _renameSelected();
      case _FolderSelectionAction.play:
        final videos =
            ref.read(folderVideosProvider(widget.folder.id)).valueOrNull ?? [];
        final video = _findVideo(videos, _selectedVideoIds.first);
        if (video != null) await _openPlayer(video, videos);
      case _FolderSelectionAction.secureFolder:
        try {
          await ref.read(videoRepositoryProvider).moveToSecureFolder(
                _selectedVideoIds.toList(growable: false),
              );
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('セキュリティフォルダを開けませんでした: $error'),
              ),
            );
          }
        }
    }
  }

  Future<void> _moveOrCopySelected({required bool isMove}) async {
    final videos =
        ref.read(folderVideosProvider(widget.folder.id)).valueOrNull ?? [];
    final destination = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RelativePathPickerScreen(
          title: isMove ? '移動' : 'コピー',
          folderOptions: videos.map((video) => video.relativePath),
        ),
      ),
    );
    if (destination == null || destination.isEmpty) return;
    final repository = ref.read(videoRepositoryProvider);
    for (final id in _selectedVideoIds) {
      if (isMove) {
        await repository.moveVideo(videoId: id, relativePath: destination);
      } else {
        await repository.copyVideo(videoId: id, relativePath: destination);
      }
    }
    await repository.refreshIndex();
    _clearSelection();
  }

  Future<void> _renameSelected() async {
    final id = _selectedVideoIds.first;
    final video = await ref.read(videoRepositoryProvider).getVideo(id);
    if (video == null || !mounted) return;
    final controller = TextEditingController(text: video.displayName);
    var name = video.displayName;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('動画の名前を変更'),
          content: TextField(
            controller: controller,
            autofocus: true,
            onChanged: (value) => setDialogState(() => name = value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: name.isEmpty || name == video.displayName
                  ? null
                  : () => Navigator.of(context).pop(name),
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
    if (result == null) return;
    await ref
        .read(videoRepositoryProvider)
        .renameVideo(videoId: id, displayName: result);
    _clearSelection();
  }

  Future<void> _openPlayer(Video video, List<Video> videos) async {
    final ids = videos.map((item) => item.id).toList(growable: false);
    final index = ids.indexOf(video.id);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenPlayerScreen(
          videoId: video.id,
          playlistVideoIds: ids,
          playlistInitialIndex: index < 0 ? 0 : index,
        ),
      ),
    );
  }

  void _moveInstantSelection(List<Video> videos, int offset) {
    if (videos.isEmpty) return;
    final current = videos.indexWhere((video) => video.id == _instantVideoId);
    final next =
        (current < 0 ? 0 : current + offset).clamp(0, videos.length - 1);
    setState(() => _instantVideoId = videos[next].id);
  }

  Video? _findVideo(List<Video> videos, String? id) {
    if (id == null) return null;
    for (final video in videos) {
      if (video.id == id) return video;
    }
    return null;
  }

  LibraryViewMode get _nextViewMode => switch (_viewMode) {
        LibraryViewMode.list => LibraryViewMode.grid,
        LibraryViewMode.grid => LibraryViewMode.enlarged,
        LibraryViewMode.enlarged => LibraryViewMode.list,
      };

  String get _nextViewModeLabel => switch (_nextViewMode) {
        LibraryViewMode.list => 'リスト表示',
        LibraryViewMode.grid => 'グリッド表示',
        LibraryViewMode.enlarged => '拡大表示',
      };

  IconData get _nextViewModeIcon => switch (_nextViewMode) {
        LibraryViewMode.list => Icons.view_list,
        LibraryViewMode.grid => Icons.grid_view,
        LibraryViewMode.enlarged => Icons.view_agenda_outlined,
      };
}

class _InstantPlayerPanel extends StatelessWidget {
  const _InstantPlayerPanel({
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
                    key: ValueKey('instant-${video.id}'),
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

class _FolderSelectionBar extends StatelessWidget {
  const _FolderSelectionBar({
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
    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            onPressed: enabled ? onShare : null,
            icon: const Icon(Icons.share_outlined),
            label: const Text('共有'),
          ),
          TextButton.icon(
            onPressed: enabled ? onDelete : null,
            icon: const Icon(Icons.delete_outline),
            label: const Text('削除'),
          ),
          TextButton.icon(
            onPressed: enabled ? onMore : null,
            icon: const Icon(Icons.more_vert),
            label: const Text('その他'),
          ),
        ],
      ),
    );
  }
}

enum _FolderVideoMenuAction { edit, sort, instantPlayer }

enum _FolderSelectionAction {
  editor,
  copy,
  move,
  rename,
  play,
  secureFolder,
}
