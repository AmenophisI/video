const _invalidFileNamePattern = r'[\\/:*?"<>|]';
const _invalidPathSegmentPattern = r'[\\:*?"<>|]';

final RegExp _invalidFileNameRegExp = RegExp(_invalidFileNamePattern);
final RegExp _invalidPathSegmentRegExp = RegExp(_invalidPathSegmentPattern);

String fileNameExtension(String displayName) {
  final dotIndex = displayName.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex == displayName.length - 1) {
    return '';
  }

  return displayName.substring(dotIndex);
}

String fileNameBase(String displayName) {
  final extension = fileNameExtension(displayName);
  if (extension.isEmpty) {
    return displayName;
  }

  return displayName.substring(0, displayName.length - extension.length);
}

String composeDisplayName({
  required String baseName,
  required String extension,
}) {
  final trimmedBase = baseName.trim();
  if (extension.isEmpty) {
    return trimmedBase;
  }

  if (trimmedBase.toLowerCase().endsWith(extension.toLowerCase())) {
    return trimmedBase;
  }

  return '$trimmedBase$extension';
}

bool attemptsExtensionChange({
  required String baseName,
  required String originalExtension,
}) {
  if (originalExtension.isEmpty) {
    return false;
  }

  final enteredExtension = fileNameExtension(baseName.trim());
  return enteredExtension.isNotEmpty &&
      enteredExtension.toLowerCase() != originalExtension.toLowerCase();
}

String? validateFileName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) {
    return 'ファイル名を入力してください';
  }

  if (_invalidFileNameRegExp.hasMatch(trimmed)) {
    return r'ファイル名に \ / : * ? " < > | は使えません';
  }

  if (trimmed == '.' || trimmed == '..') {
    return 'このファイル名は使えません';
  }

  return null;
}

String? validateRelativePath(String relativePath) {
  final normalized = normalizeRelativePath(relativePath);
  if (normalized == null) {
    return 'フォルダを入力してください';
  }

  final segments = normalized
      .replaceAll(RegExp(r'/$'), '')
      .split('/')
      .where((segment) => segment.isNotEmpty);

  for (final segment in segments) {
    if (segment == '.' || segment == '..') {
      return 'このフォルダ名は使えません';
    }
    if (_invalidPathSegmentRegExp.hasMatch(segment)) {
      return r'フォルダ名に \ : * ? " < > | は使えません';
    }
  }

  return null;
}

String? normalizeRelativePath(String relativePath) {
  final normalized = relativePath
      .trim()
      .replaceAll('\\', '/')
      .split('/')
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) => segment.trim())
      .join('/');

  if (normalized.isEmpty) {
    return null;
  }

  return '$normalized/';
}

String nextAvailableDisplayName({
  required String desiredDisplayName,
  required Iterable<String> existingDisplayNames,
}) {
  final existing =
      existingDisplayNames.map((name) => name.toLowerCase()).toSet();
  if (!existing.contains(desiredDisplayName.toLowerCase())) {
    return desiredDisplayName;
  }

  final base = fileNameBase(desiredDisplayName);
  final extension = fileNameExtension(desiredDisplayName);
  final copyName = '$base (copy)$extension';
  if (!existing.contains(copyName.toLowerCase())) {
    return copyName;
  }

  var index = 2;
  while (true) {
    final candidate = '$base ($index)$extension';
    if (!existing.contains(candidate.toLowerCase())) {
      return candidate;
    }
    index += 1;
  }
}
