import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class NativeVideoPlayerController {
  MethodChannel? _channel;
  final StreamController<void> _completedController =
      StreamController<void>.broadcast();

  Stream<void> get completed => _completedController.stream;

  Future<Duration?> currentPosition() async {
    final channel = _channel;
    if (channel == null) {
      return null;
    }

    final milliseconds = await channel.invokeMethod<int>('position');
    if (milliseconds == null) {
      return null;
    }

    return Duration(milliseconds: milliseconds);
  }

  Future<Duration?> duration() async {
    final channel = _channel;
    if (channel == null) {
      return null;
    }

    final milliseconds = await channel.invokeMethod<int>('duration');
    if (milliseconds == null) {
      return null;
    }

    return Duration(milliseconds: milliseconds);
  }

  Future<void> play() async {
    await _channel?.invokeMethod<void>('play');
  }

  Future<void> pause() async {
    await _channel?.invokeMethod<void>('pause');
  }

  Future<bool?> isPlaying() async {
    return _channel?.invokeMethod<bool>('isPlaying');
  }

  Future<void> seekTo(Duration position) async {
    await _channel?.invokeMethod<void>(
      'seekTo',
      {'positionMs': position.inMilliseconds},
    );
  }

  Future<void> setMuted(bool muted) async {
    await _channel?.invokeMethod<void>(
      'setMuted',
      {'muted': muted},
    );
  }

  Future<void> setSubtitleEnabled(bool enabled) async {
    await _channel?.invokeMethod<void>(
      'setSubtitleEnabled',
      {'enabled': enabled},
    );
  }

  void _attach(int viewId) {
    _channel = MethodChannel('video_player/android_video_view_$viewId');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'completed') {
        _completedController.add(null);
      }
    });
  }

  void _detach() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
  }

  void dispose() {
    _completedController.close();
  }
}

class NativeVideoPlayerView extends StatefulWidget {
  const NativeVideoPlayerView({
    required this.controller,
    required this.uri,
    required this.initialPosition,
    this.subtitleUri,
    super.key,
  });

  final NativeVideoPlayerController controller;
  final Uri uri;
  final Duration initialPosition;
  final Uri? subtitleUri;

  @override
  State<NativeVideoPlayerView> createState() => _NativeVideoPlayerViewState();
}

class _NativeVideoPlayerViewState extends State<NativeVideoPlayerView> {
  @override
  void dispose() {
    unawaited(widget.controller.pause());
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const _UnsupportedPlayerView();
    }

    return AndroidView(
      viewType: 'video_player/android_video_view',
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      layoutDirection: TextDirection.ltr,
      creationParams: {
        'uri': widget.uri.toString(),
        'initialPositionMs': widget.initialPosition.inMilliseconds,
        'subtitleUri': widget.subtitleUri?.toString(),
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: widget.controller._attach,
    );
  }
}

class _UnsupportedPlayerView extends StatelessWidget {
  const _UnsupportedPlayerView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: Text(
          'この環境では動画再生を利用できません',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
