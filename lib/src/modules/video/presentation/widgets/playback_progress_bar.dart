import 'package:flutter/material.dart';

class PlaybackProgressBar extends StatelessWidget {
  const PlaybackProgressBar({
    required this.progress,
    super.key,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0, 1).toDouble();

    return Semantics(
      label: '視聴進捗',
      value: '${(normalizedProgress * 100).round()}パーセント',
      child: LinearProgressIndicator(
        value: normalizedProgress,
        minHeight: 4,
        backgroundColor: Colors.black26,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
