import 'package:flutter/material.dart';

import '../../../shared/utils/file_name_utils.dart';

class RelativePathPickerScreen extends StatelessWidget {
  const RelativePathPickerScreen({
    required this.title,
    required this.folderOptions,
    super.key,
  });

  final String title;
  final Iterable<String?> folderOptions;

  @override
  Widget build(BuildContext context) {
    final paths = folderOptions
        .whereType<String>()
        .map(normalizeRelativePath)
        .whereType<String>()
        .toSet()
        .toList(growable: false)
      ..sort();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: paths.isEmpty
          ? const Center(child: Text('保存先フォルダがありません'))
          : GridView.builder(
              padding: const EdgeInsets.all(18),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.9,
              ),
              itemCount: paths.length,
              itemBuilder: (context, index) {
                final path = paths[index];
                final label =
                    path.replaceAll(RegExp(r'/+$'), '').split('/').last;
                return Semantics(
                  button: true,
                  label: '$label フォルダ',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).pop(path),
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.folder,
                                size: 54,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
