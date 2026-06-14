String formatDuration(Duration? duration) {
  if (duration == null) {
    return '--:--';
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$minutes:$seconds';
  }

  return '${duration.inMinutes}:$seconds';
}

String formatDate(DateTime? dateTime) {
  if (dateTime == null) {
    return '--';
  }

  return '${dateTime.year.toString().padLeft(4, '0')}/'
      '${dateTime.month.toString().padLeft(2, '0')}/'
      '${dateTime.day.toString().padLeft(2, '0')}';
}

String formatFileSize(int? bytes) {
  if (bytes == null || bytes < 0) {
    return '--';
  }

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }

  final text =
      unitIndex == 0 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$text ${units[unitIndex]}';
}

String formatResolution({
  required int? width,
  required int? height,
  required int? rotationDegrees,
}) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return '--';
  }

  final rotation = rotationDegrees == null || rotationDegrees == 0
      ? ''
      : ' / $rotationDegrees度回転';
  return '$width'
      'x$height$rotation';
}

String formatBitrate(int? bitrate) {
  if (bitrate == null || bitrate <= 0) {
    return '--';
  }

  if (bitrate >= 1000 * 1000) {
    return '${(bitrate / (1000 * 1000)).toStringAsFixed(1)} Mbps';
  }

  return '${(bitrate / 1000).toStringAsFixed(0)} kbps';
}

String formatFrameRate(double? frameRate) {
  if (frameRate == null || frameRate <= 0) {
    return '--';
  }

  return '${frameRate.toStringAsFixed(2)} fps';
}
