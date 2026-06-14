import 'package:flutter/material.dart';

enum FileConflictResolution {
  skip,
  rename,
  replace,
}

Future<FileConflictResolution?> showFileConflictDialog({
  required BuildContext context,
  required bool isMove,
  required bool isBatch,
  required int conflictCount,
}) {
  return showDialog<FileConflictResolution>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('同名ファイルがあります'),
      content: Text(
        isBatch
            ? '$conflictCount件の動画で移動先・コピー先に同名ファイルがあります。処理方法を選択してください。'
            : '移動先・コピー先に同名ファイルがあります。処理方法を選択してください。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(FileConflictResolution.skip),
          child: const Text('スキップ'),
        ),
        if (!isMove)
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(FileConflictResolution.rename),
            child: const Text('別名保存'),
          ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(FileConflictResolution.replace),
          child: const Text('置き換え'),
        ),
      ],
    ),
  );
}
