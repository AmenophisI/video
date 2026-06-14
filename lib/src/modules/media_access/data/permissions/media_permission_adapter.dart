import 'package:flutter/services.dart';

import '../../domain/media_permission.dart';

class MediaPermissionAdapter {
  const MediaPermissionAdapter();

  static const MethodChannel _channel = MethodChannel(
    'video_player/media_store',
  );
  static Future<MediaPermission>? _pendingVideoPermissionRequest;
  static Future<MediaPermission>? _pendingAdditionalVideoAccessRequest;

  Future<MediaPermission> checkPermission() async {
    final status = await _channel.invokeMethod<String>(
      'checkVideoPermission',
    );

    return _fromPlatformStatus(status);
  }

  Future<MediaPermission> requestPermission() async {
    final pending = _pendingVideoPermissionRequest;
    if (pending != null) {
      return pending;
    }

    final request = _requestPermission('requestVideoPermission');
    _pendingVideoPermissionRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingVideoPermissionRequest, request)) {
        _pendingVideoPermissionRequest = null;
      }
    }
  }

  Future<MediaPermission> requestAdditionalVideoAccess() async {
    final pending = _pendingAdditionalVideoAccessRequest;
    if (pending != null) {
      return pending;
    }

    final request = _requestPermission('requestAdditionalVideoAccess');
    _pendingAdditionalVideoAccessRequest = request;
    try {
      return await request;
    } finally {
      if (identical(_pendingAdditionalVideoAccessRequest, request)) {
        _pendingAdditionalVideoAccessRequest = null;
      }
    }
  }

  Future<void> openAppSettings() async {
    await _channel.invokeMethod<void>('openAppSettings');
  }

  Future<MediaPermission> _requestPermission(String methodName) async {
    try {
      final status = await _channel.invokeMethod<String>(methodName);
      return _fromPlatformStatus(status);
    } on PlatformException catch (error) {
      if (error.code == 'permission_request_in_progress') {
        return checkPermission();
      }
      rethrow;
    }
  }

  MediaPermission _fromPlatformStatus(String? status) {
    return switch (status) {
      'granted' => MediaPermission.granted,
      'limited' => MediaPermission.limited,
      'denied' => MediaPermission.denied,
      _ => MediaPermission.unknown,
    };
  }
}
