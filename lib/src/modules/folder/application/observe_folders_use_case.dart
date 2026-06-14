import '../domain/folder.dart';
import '../domain/folder_repository.dart';

class ObserveFoldersUseCase {
  const ObserveFoldersUseCase(this._repository);

  final FolderRepository _repository;

  Stream<List<Folder>> call() {
    return _repository.watchFolders();
  }
}
