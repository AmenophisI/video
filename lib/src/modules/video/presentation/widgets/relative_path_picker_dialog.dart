import 'package:flutter/material.dart';

import '../../../../shared/utils/file_name_utils.dart';

class RelativePathPickerDialog extends StatefulWidget {
  const RelativePathPickerDialog({
    required this.title,
    required this.actionLabel,
    required this.initialPath,
    required this.folderOptions,
    this.inputLabel = '移動先・コピー先フォルダ',
    super.key,
  });

  final String title;
  final String actionLabel;
  final String initialPath;
  final Iterable<String> folderOptions;
  final String inputLabel;

  @override
  State<RelativePathPickerDialog> createState() =>
      _RelativePathPickerDialogState();
}

class _RelativePathPickerDialogState extends State<RelativePathPickerDialog> {
  late final TextEditingController _controller;

  List<String> get _options {
    final normalized = <String>{
      for (final path in widget.folderOptions)
        if (normalizeRelativePath(path) != null) normalizeRelativePath(path)!,
      if (normalizeRelativePath(widget.initialPath) != null)
        normalizeRelativePath(widget.initialPath)!,
      'Movies/',
      'Download/',
    }.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return normalized;
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: normalizeRelativePath(widget.initialPath)?.replaceAll(
            RegExp(r'/$'),
            '',
          ) ??
          'Movies',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: widget.inputLabel,
                hintText: 'Movies/MyFolder',
                prefixIcon: const Icon(Icons.folder_outlined),
              ),
            ),
            if (_options.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '既存フォルダ',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.folder),
                      title: Text(option.replaceAll(RegExp(r'/$'), '')),
                      onTap: () {
                        _controller.text = option.replaceAll(
                          RegExp(r'/$'),
                          '',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          icon: const Icon(Icons.check),
          label: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
