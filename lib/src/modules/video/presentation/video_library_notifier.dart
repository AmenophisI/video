import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/video_providers.dart';
import '../domain/video_query.dart';

class VideoLibraryNotifier extends Notifier<VideoQuery> {
  @override
  VideoQuery build() {
    return ref.watch(videoQueryProvider);
  }

  void updateSearchText(String value) {
    state = state.copyWith(searchText: value);
  }
}
