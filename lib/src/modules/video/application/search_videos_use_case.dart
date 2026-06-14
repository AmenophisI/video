import '../domain/video_query.dart';

class SearchVideosUseCase {
  const SearchVideosUseCase();

  VideoQuery call(VideoQuery currentQuery, String searchText) {
    return currentQuery.copyWith(searchText: searchText);
  }
}
