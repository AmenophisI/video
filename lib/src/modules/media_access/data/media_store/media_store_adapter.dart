import 'dart:async';

import 'package:flutter/services.dart';

import 'media_store_video_dto.dart';

class MediaStoreAdapter {
  MediaStoreAdapter() {
    _ensureMethodHandler();
  }

  static const MethodChannel _channel = MethodChannel(
    'video_player/media_store',
  );
  static final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  static bool _handlerInitialized = false;

  Stream<void> watchChanges() {
    _ensureMethodHandler();
    return _changesController.stream;
  }

  Future<List<MediaStoreVideoDto>> queryVideos() async {
    final result = await _channel.invokeListMethod<dynamic>('queryVideos');
    if (result == null) {
      throw const MediaStoreQueryException(
        'MediaStoreから動画一覧を取得できませんでした。',
      );
    }

    return [
      for (final item in result)
        if (item is Map) MediaStoreVideoDto.fromMap(item),
    ];
  }

  void _ensureMethodHandler() {
    if (_handlerInitialized) {
      return;
    }

    _handlerInitialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'mediaStoreChanged') {
        _changesController.add(null);
      }
    });
  }
}

class MediaStoreQueryException implements Exception {
  const MediaStoreQueryException(this.message);

  final String message;

  @override
  String toString() => message;
}
