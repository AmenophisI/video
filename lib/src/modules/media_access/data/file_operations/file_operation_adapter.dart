import 'package:flutter/services.dart';

class FileOperationAdapter {
  const FileOperationAdapter();

  static const MethodChannel _channel = MethodChannel(
    'video_player/media_store',
  );

  Future<void> share(Uri uri) async {
    await _channel.invokeMethod<void>(
      'shareVideo',
      {'uri': uri.toString()},
    );
  }

  Future<void> shareMultiple(List<Uri> uris) async {
    await _channel.invokeMethod<void>(
      'shareVideos',
      {'uris': uris.map((uri) => uri.toString()).toList(growable: false)},
    );
  }

  Future<void> moveToSecureFolder(List<Uri> uris) async {
    await _channel.invokeMethod<void>(
      'moveToSecureFolder',
      {'uris': uris.map((uri) => uri.toString()).toList(growable: false)},
    );
  }

  Future<void> openEditor(Uri uri) async {
    await _channel.invokeMethod<void>(
      'openEditor',
      {'uri': uri.toString()},
    );
  }

  Future<void> openExternalPlayer(Uri uri) async {
    await _channel.invokeMethod<void>(
      'openExternalPlayer',
      {'uri': uri.toString()},
    );
  }

  Future<void> delete(Uri uri) async {
    await _channel.invokeMethod<void>(
      'deleteVideo',
      {'uri': uri.toString()},
    );
  }

  Future<void> deleteMultiple(List<Uri> uris) async {
    await _channel.invokeMethod<void>(
      'deleteVideos',
      {'uris': uris.map((uri) => uri.toString()).toList(growable: false)},
    );
  }

  Future<void> rename({
    required Uri uri,
    required String displayName,
  }) async {
    await _channel.invokeMethod<void>(
      'renameVideo',
      {
        'uri': uri.toString(),
        'displayName': displayName,
      },
    );
  }

  Future<void> move({
    required Uri uri,
    required String relativePath,
  }) async {
    await _channel.invokeMethod<void>(
      'moveVideo',
      {
        'uri': uri.toString(),
        'relativePath': relativePath,
      },
    );
  }

  Future<void> copy({
    required Uri uri,
    required String displayName,
    required String relativePath,
    String? mimeType,
  }) async {
    await _channel.invokeMethod<void>(
      'copyVideo',
      {
        'uri': uri.toString(),
        'displayName': displayName,
        'relativePath': relativePath,
        'mimeType': mimeType,
      },
    );
  }

  Future<void> createFolder(String relativePath) async {
    await _channel.invokeMethod<void>(
      'createFolder',
      {'relativePath': relativePath},
    );
  }
}
