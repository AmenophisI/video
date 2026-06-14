import 'package:flutter/services.dart';

class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String versionName;
  final String buildNumber;

  String get versionLabel => '$versionName ($buildNumber)';
}

class AppInfoAdapter {
  const AppInfoAdapter();

  static const MethodChannel _channel = MethodChannel(
    'video_player/media_store',
  );

  Future<AppInfo> getAppInfo() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('getAppInfo');
    final data = raw ?? const <String, Object?>{};

    return AppInfo(
      appName: data['appName'] as String? ?? '動画ライブラリ',
      packageName: data['packageName'] as String? ?? '',
      versionName: data['versionName'] as String? ?? 'unknown',
      buildNumber: data['buildNumber'] as String? ?? 'unknown',
    );
  }
}
