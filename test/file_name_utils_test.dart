import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/shared/utils/file_name_utils.dart';

void main() {
  group('fileNameUtils', () {
    test('preserves extensions when composing display names', () {
      expect(
        composeDisplayName(baseName: 'holiday', extension: '.mp4'),
        'holiday.mp4',
      );
      expect(
        composeDisplayName(baseName: 'holiday.mp4', extension: '.mp4'),
        'holiday.mp4',
      );
    });

    test('detects attempted extension changes', () {
      expect(
        attemptsExtensionChange(
          baseName: 'holiday.avi',
          originalExtension: '.mp4',
        ),
        isTrue,
      );
      expect(
        attemptsExtensionChange(
          baseName: 'holiday.mp4',
          originalExtension: '.mp4',
        ),
        isFalse,
      );
      expect(
        attemptsExtensionChange(
          baseName: 'holiday',
          originalExtension: '.mp4',
        ),
        isFalse,
      );
    });

    test('rejects invalid file names and relative paths', () {
      expect(validateFileName('bad/name.mp4'), isNotNull);
      expect(validateFileName('movie.mp4'), isNull);
      expect(validateRelativePath('Movies/../Secret'), isNotNull);
      expect(validateRelativePath('Movies/Travel'), isNull);
    });

    test('returns next available display name for conflicts', () {
      expect(
        nextAvailableDisplayName(
          desiredDisplayName: 'movie.mp4',
          existingDisplayNames: const ['movie.mp4'],
        ),
        'movie (copy).mp4',
      );
      expect(
        nextAvailableDisplayName(
          desiredDisplayName: 'movie.mp4',
          existingDisplayNames: const ['movie.mp4', 'movie (copy).mp4'],
        ),
        'movie (2).mp4',
      );
    });
  });
}
