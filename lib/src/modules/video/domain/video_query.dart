enum VideoSortKey {
  title,
  createdAt,
  modifiedAt,
  sizeBytes,
  duration,
}

enum SortOrder {
  ascending,
  descending,
}

enum VideoFilter {
  all,
  hdr,
  video360,
  slowMotion,
  hyperlapse,
  drm,
  largeSize,
  recentlyAdded,
  recentlyPlayed,
  favorite,
  privateVideos,
  unplayable,
}

enum VideoSearchTarget {
  all,
  title,
  folder,
}

class VideoQuery {
  const VideoQuery({
    this.searchText = '',
    this.searchTarget = VideoSearchTarget.all,
    this.folderId,
    this.sortKey = VideoSortKey.modifiedAt,
    this.sortOrder = SortOrder.descending,
    this.filter = VideoFilter.all,
  });

  final String searchText;
  final VideoSearchTarget searchTarget;
  final String? folderId;
  final VideoSortKey sortKey;
  final SortOrder sortOrder;
  final VideoFilter filter;

  VideoQuery copyWith({
    String? searchText,
    VideoSearchTarget? searchTarget,
    String? folderId,
    VideoSortKey? sortKey,
    SortOrder? sortOrder,
    VideoFilter? filter,
  }) {
    return VideoQuery(
      searchText: searchText ?? this.searchText,
      searchTarget: searchTarget ?? this.searchTarget,
      folderId: folderId ?? this.folderId,
      sortKey: sortKey ?? this.sortKey,
      sortOrder: sortOrder ?? this.sortOrder,
      filter: filter ?? this.filter,
    );
  }
}
