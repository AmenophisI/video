import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../media_access/data/thumbnails/thumbnail_adapter.dart';
import '../../../media_access/data/thumbnails/thumbnail_cache.dart';
import '../../domain/video.dart';

class VideoThumbnail extends StatefulWidget {
  const VideoThumbnail({
    required this.video,
    super.key,
  });

  final Video video;

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  Uint8List? _memoryBytes;
  late Future<ThumbnailResult> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _memoryBytes = ThumbnailCache.memoryBytesFor(widget.video.id);
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant VideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.uri != widget.video.uri) {
      _memoryBytes = ThumbnailCache.memoryBytesFor(widget.video.id);
      _thumbnailFuture = _loadThumbnail();
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryBytes = _memoryBytes;
    if (memoryBytes != null && memoryBytes.isNotEmpty) {
      return _ThumbnailImage(
        bytes: memoryBytes,
        fallback: _ThumbnailPlaceholder(video: widget.video),
      );
    }

    return FutureBuilder<ThumbnailResult>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        final bytes = snapshot.data?.bytes;
        if (bytes == null || bytes.isEmpty) {
          return _ThumbnailPlaceholder(video: widget.video);
        }

        return _ThumbnailImage(
          bytes: bytes,
          fallback: _ThumbnailPlaceholder(video: widget.video),
        );
      },
    );
  }

  Future<ThumbnailResult> _loadThumbnail() async {
    return VideoThumbnailLoader.load(widget.video);
  }
}

class VideoThumbnailLoader {
  const VideoThumbnailLoader._();

  static final Map<String, Future<ThumbnailResult>> _inFlight = {};

  static Future<ThumbnailResult> load(Video video) {
    final existing = _inFlight[video.id];
    if (existing != null) {
      return existing;
    }

    final future = _load(video);
    _inFlight[video.id] = future;
    unawaited(
      future.whenComplete(() {
        _inFlight.remove(video.id);
      }),
    );
    return future;
  }

  static void prefetch(Iterable<Video> videos, {int limit = 12}) {
    for (final video in videos.take(limit)) {
      unawaited(load(video));
    }
  }

  static Future<ThumbnailResult> _load(Video video) async {
    final cacheKey = video.id;
    final cachedBytes = await const ThumbnailCache().get(cacheKey);
    if (cachedBytes != null) {
      return ThumbnailResult(videoUri: video.uri, bytes: cachedBytes);
    }

    final result = await const ThumbnailAdapter().loadThumbnail(
      videoUri: video.uri,
      mediaStoreId: video.mediaStoreId,
    );
    final bytes = result.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      await const ThumbnailCache().put(cacheKey, bytes);
    }

    return result;
  }
}

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({
    required this.bytes,
    required this.fallback,
  });

  final Uint8List bytes;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({
    required this.video,
  });

  final Video video;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Icon(
        Icons.play_circle_fill,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
