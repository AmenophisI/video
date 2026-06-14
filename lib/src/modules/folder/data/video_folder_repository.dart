import '../../video/domain/video_query.dart';
import '../../video/domain/video_repository.dart';
import '../domain/folder.dart';
import '../domain/folder_repository.dart';

class VideoFolderRepository implements FolderRepository {
  const VideoFolderRepository(this._videoRepository);

  final VideoRepository _videoRepository;

  @override
  Stream<List<Folder>> watchFolders() {
    return _videoRepository.watchVideos(const VideoQuery()).map((videos) {
      final foldersById = <String, _FolderAccumulator>{};

      for (final video in videos) {
        final accumulator = foldersById.putIfAbsent(
          video.folderId,
          () => _FolderAccumulator(
            id: video.folderId,
            name: video.folderName,
          ),
        );
        accumulator.videoCount += 1;
        accumulator.totalSizeBytes += video.sizeBytes ?? 0;
        accumulator.storageLabel ??= _storageLabel(video.relativePath);

        final modifiedAt = video.modifiedAt ?? video.createdAt;
        final latest = accumulator.latestModifiedAt;
        if (modifiedAt != null &&
            (latest == null || modifiedAt.isAfter(latest))) {
          accumulator.latestModifiedAt = modifiedAt;
          accumulator.representativeVideoId = video.id;
        } else {
          accumulator.representativeVideoId ??= video.id;
        }
      }

      final folders = foldersById.values.map((entry) {
        return Folder(
          id: entry.id,
          name: entry.name,
          videoCount: entry.videoCount,
          representativeVideoId: entry.representativeVideoId,
          latestModifiedAt: entry.latestModifiedAt,
          totalSizeBytes: entry.totalSizeBytes,
          storageLabel: entry.storageLabel,
        );
      }).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      return List<Folder>.unmodifiable(folders);
    });
  }

  String _storageLabel(String? relativePath) {
    final path = relativePath?.toLowerCase() ?? '';
    if (path.startsWith('dcim/') || path.startsWith('pictures/')) {
      return 'カメラ/写真';
    }
    if (path.startsWith('download/')) {
      return 'ダウンロード';
    }
    if (path.startsWith('movies/')) {
      return 'Movies';
    }

    return '共有ストレージ';
  }
}

class _FolderAccumulator {
  _FolderAccumulator({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
  int videoCount = 0;
  int totalSizeBytes = 0;
  String? representativeVideoId;
  DateTime? latestModifiedAt;
  String? storageLabel;
}
