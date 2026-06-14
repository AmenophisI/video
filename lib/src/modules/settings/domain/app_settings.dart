enum LibraryViewMode {
  grid,
  list,
}

enum PrivateLockMethod {
  pin,
  deviceCredential,
  pinOrDeviceCredential,
}

extension PrivateLockMethodX on PrivateLockMethod {
  String get label {
    return switch (this) {
      PrivateLockMethod.pin => 'PINのみ',
      PrivateLockMethod.deviceCredential => '端末認証のみ',
      PrivateLockMethod.pinOrDeviceCredential => '端末認証またはPIN',
    };
  }
}

class AppSettings {
  const AppSettings({
    this.viewMode = LibraryViewMode.grid,
    this.rememberPlaybackPosition = true,
    this.showPlaybackProgress = true,
    this.showVideoTags = true,
    this.enableInstantPlayer = true,
    this.thumbnailCacheLimitMb = 512,
    this.privatePin,
    this.privateLockMethod = PrivateLockMethod.pinOrDeviceCredential,
  });

  final LibraryViewMode viewMode;
  final bool rememberPlaybackPosition;
  final bool showPlaybackProgress;
  final bool showVideoTags;
  final bool enableInstantPlayer;
  final int thumbnailCacheLimitMb;
  final String? privatePin;
  final PrivateLockMethod privateLockMethod;

  bool get hasPrivatePin => privatePin?.isNotEmpty ?? false;
  bool get canUsePrivatePin {
    return privateLockMethod != PrivateLockMethod.deviceCredential &&
        hasPrivatePin;
  }

  AppSettings copyWith({
    LibraryViewMode? viewMode,
    bool? rememberPlaybackPosition,
    bool? showPlaybackProgress,
    bool? showVideoTags,
    bool? enableInstantPlayer,
    int? thumbnailCacheLimitMb,
    String? privatePin,
    PrivateLockMethod? privateLockMethod,
    bool clearPrivatePin = false,
  }) {
    return AppSettings(
      viewMode: viewMode ?? this.viewMode,
      rememberPlaybackPosition:
          rememberPlaybackPosition ?? this.rememberPlaybackPosition,
      showPlaybackProgress: showPlaybackProgress ?? this.showPlaybackProgress,
      showVideoTags: showVideoTags ?? this.showVideoTags,
      enableInstantPlayer: enableInstantPlayer ?? this.enableInstantPlayer,
      thumbnailCacheLimitMb:
          thumbnailCacheLimitMb ?? this.thumbnailCacheLimitMb,
      privatePin: clearPrivatePin ? null : privatePin ?? this.privatePin,
      privateLockMethod: privateLockMethod ?? this.privateLockMethod,
    );
  }
}
