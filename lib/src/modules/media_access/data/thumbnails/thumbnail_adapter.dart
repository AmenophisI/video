import 'package:flutter/services.dart';

class ThumbnailResult {
  const ThumbnailResult({
    required this.videoUri,
    this.bytes,
    this.thumbnailUri,
  });

  final Uri videoUri;
  final Uint8List? bytes;
  final Uri? thumbnailUri;
}

class ThumbnailAdapter {
  const ThumbnailAdapter();

  static const MethodChannel _channel = MethodChannel(
    'video_player/media_store',
  );

  Future<ThumbnailResult> loadThumbnail({
    required Uri videoUri,
    required int mediaStoreId,
    int width = 320,
    int height = 180,
  }) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>(
        'loadThumbnail',
        {
          'uri': videoUri.toString(),
          'mediaStoreId': mediaStoreId,
          'width': width,
          'height': height,
        },
      );

      return ThumbnailResult(
        videoUri: videoUri,
        bytes: bytes,
      );
    } on PlatformException {
      return ThumbnailResult(videoUri: videoUri);
    } on MissingPluginException {
      return ThumbnailResult(videoUri: videoUri);
    }
  }
}
