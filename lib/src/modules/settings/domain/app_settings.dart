enum LibraryViewMode {
  list,
  grid,
  enlarged,
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
    this.viewMode = LibraryViewMode.list,
    this.lastTabIndex = 0,
    this.rememberPlaybackPosition = true,
    this.showPlaybackProgress = true,
    this.showVideoTags = true,
    this.enableInstantPlayer = false,
    this.autoPlayNext = false,
    this.autoRepeat = false,
    this.backgroundPlayback = false,
    this.showSpeedController = true,
    this.videoBrightness = 0.5,
    this.thumbnailCacheLimitMb = 512,
    this.privatePin,
    this.privateLockMethod = PrivateLockMethod.pinOrDeviceCredential,
  });

  final LibraryViewMode viewMode;
  final int lastTabIndex;
  final bool rememberPlaybackPosition;
  final bool showPlaybackProgress;
  final bool showVideoTags;
  final bool enableInstantPlayer;
  final bool autoPlayNext;
  final bool autoRepeat;
  final bool backgroundPlayback;
  final bool showSpeedController;
  final double videoBrightness;
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
    int? lastTabIndex,
    bool? rememberPlaybackPosition,
    bool? showPlaybackProgress,
    bool? showVideoTags,
    bool? enableInstantPlayer,
    bool? autoPlayNext,
    bool? autoRepeat,
    bool? backgroundPlayback,
    bool? showSpeedController,
    double? videoBrightness,
    int? thumbnailCacheLimitMb,
    String? privatePin,
    PrivateLockMethod? privateLockMethod,
    bool clearPrivatePin = false,
  }) {
    return AppSettings(
      viewMode: viewMode ?? this.viewMode,
      lastTabIndex: lastTabIndex ?? this.lastTabIndex,
      rememberPlaybackPosition:
          rememberPlaybackPosition ?? this.rememberPlaybackPosition,
      showPlaybackProgress: showPlaybackProgress ?? this.showPlaybackProgress,
      showVideoTags: showVideoTags ?? this.showVideoTags,
      enableInstantPlayer: enableInstantPlayer ?? this.enableInstantPlayer,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      autoRepeat: autoRepeat ?? this.autoRepeat,
      backgroundPlayback: backgroundPlayback ?? this.backgroundPlayback,
      showSpeedController: showSpeedController ?? this.showSpeedController,
      videoBrightness: videoBrightness ?? this.videoBrightness,
      thumbnailCacheLimitMb:
          thumbnailCacheLimitMb ?? this.thumbnailCacheLimitMb,
      privatePin: clearPrivatePin ? null : privatePin ?? this.privatePin,
      privateLockMethod: privateLockMethod ?? this.privateLockMethod,
    );
  }
}
