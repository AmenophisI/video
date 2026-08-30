import 'package:flutter/services.dart';

class PlayerSystemAdapter {
  const PlayerSystemAdapter();

  static const MethodChannel _channel = MethodChannel('video_player/system');

  Future<void> enterPictureInPicture() async {
    await _channel.invokeMethod<void>('enterPictureInPicture');
  }

  Future<void> openCastSettings() async {
    await _channel.invokeMethod<void>('openCastSettings');
  }

  Future<void> setScreenBrightness(double brightness) async {
    await _channel.invokeMethod<void>(
      'setScreenBrightness',
      brightness.clamp(0.01, 1.0),
    );
  }

  Future<void> resetScreenBrightness() async {
    await _channel.invokeMethod<void>('resetScreenBrightness');
  }

  Future<double> getMediaVolume() async {
    final volume = await _channel.invokeMethod<double>('getMediaVolume');
    return (volume ?? 0.5).clamp(0.0, 1.0);
  }

  Future<void> setMediaVolume(double volume) async {
    await _channel.invokeMethod<void>(
      'setMediaVolume',
      volume.clamp(0.0, 1.0),
    );
  }

  Future<Uri?> captureFrame({
    required Uri videoUri,
    required Duration position,
  }) async {
    final uriText = await _channel.invokeMethod<String>(
      'captureFrame',
      {
        'uri': videoUri.toString(),
        'positionMs': position.inMilliseconds,
      },
    );
    return uriText == null ? null : Uri.parse(uriText);
  }

  Future<List<Uint8List>> extractFrames({
    required Uri videoUri,
    required Duration start,
    required Duration duration,
    int frameCount = 12,
  }) async {
    final values = await _channel.invokeMethod<List<Object?>>(
      'extractFrames',
      {
        'uri': videoUri.toString(),
        'startMs': start.inMilliseconds,
        'durationMs': duration.inMilliseconds,
        'frameCount': frameCount,
      },
    );
    final frames = values?.whereType<Uint8List>().toList(growable: false) ??
        const <Uint8List>[];
    if (frames.isEmpty) {
      throw PlatformException(
        code: 'frame_extraction_failed',
        message: 'GIFに使用できるフレームがありません。',
      );
    }
    return frames;
  }

  Future<Uri> saveGif(Uint8List bytes) async {
    final uriText = await _channel.invokeMethod<String>('saveGif', bytes);
    if (uriText == null || uriText.isEmpty) {
      throw PlatformException(
        code: 'gif_save_failed',
        message: 'GIFの保存先を取得できませんでした。',
      );
    }
    return Uri.parse(uriText);
  }

  Future<void> shareGif(Uint8List bytes) async {
    await _channel.invokeMethod<void>('shareGif', bytes);
  }
}
