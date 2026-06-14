import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThumbnailCache {
  const ThumbnailCache();

  static final Map<String, Uint8List> _memoryCache = {};

  static Uint8List? memoryBytesFor(String key) {
    return _memoryCache[key];
  }

  Future<Uint8List?> get(String key) async {
    final memoryBytes = _memoryCache[key];
    if (memoryBytes != null) {
      return memoryBytes;
    }

    final file = await _fileForKey(key);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) {
      _memoryCache[key] = bytes;
      return bytes;
    }

    return null;
  }

  Future<void> put(String key, Uint8List bytes) async {
    _memoryCache[key] = bytes;
    final file = await _fileForKey(key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: false);
    await _trimToLimit();
  }

  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    final file = await _fileForKey(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clear() async {
    _memoryCache.clear();
    final directory = await _cacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<File> _fileForKey(String key) async {
    final directory = await _cacheDirectory();
    final safeKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File(path.join(directory.path, '$safeKey.jpg'));
  }

  Future<Directory> _cacheDirectory() async {
    final directory = await getTemporaryDirectory();
    return Directory(path.join(directory.path, 'video_thumbnails'));
  }

  Future<void> _trimToLimit() async {
    final limitBytes = await _cacheLimitBytes();
    if (limitBytes <= 0) {
      await clear();
      return;
    }

    final directory = await _cacheDirectory();
    if (!await directory.exists()) {
      return;
    }

    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File) {
        files.add(entity);
      }
    }

    var totalBytes = 0;
    final entries = <_ThumbnailCacheEntry>[];
    for (final file in files) {
      final stat = await file.stat();
      totalBytes += stat.size;
      entries.add(_ThumbnailCacheEntry(file: file, stat: stat));
    }

    if (totalBytes <= limitBytes) {
      return;
    }

    entries.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));
    for (final entry in entries) {
      if (totalBytes <= limitBytes) {
        break;
      }

      await entry.file.delete();
      totalBytes -= entry.stat.size;
      final key = path.basenameWithoutExtension(entry.file.path);
      _memoryCache.remove(key);
    }
  }

  Future<int> _cacheLimitBytes() async {
    final preferences = SharedPreferencesAsync();
    final limitMb =
        await preferences.getInt('settings.thumbnailCacheLimitMb') ?? 512;
    return limitMb * 1024 * 1024;
  }
}

class _ThumbnailCacheEntry {
  const _ThumbnailCacheEntry({
    required this.file,
    required this.stat,
  });

  final File file;
  final FileStat stat;
}
