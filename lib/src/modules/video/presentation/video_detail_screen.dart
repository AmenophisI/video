import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/duration_format.dart';
import '../application/video_providers.dart';
import '../domain/video.dart';

class VideoDetailScreen extends ConsumerWidget {
  const VideoDetailScreen({
    required this.videoId,
    super.key,
  });

  final String videoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videoAsync = ref.watch(videoByIdProvider(videoId));

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFF050609),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          leading: const BackButton(),
          titleSpacing: 0,
          title: const Text(
            '詳細',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
        ),
        body: videoAsync.when(
          data: (video) {
            if (video == null) {
              return const Center(child: Text('動画が見つかりません'));
            }
            return _SamsungVideoDetails(video: video);
          },
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _SamsungVideoDetails extends StatelessWidget {
  const _SamsungVideoDetails({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, String value})>[
      (
        label: '日時',
        value: _formatDateTime(video.modifiedAt ?? video.createdAt)
      ),
      (label: '名前', value: video.displayName),
      (label: 'サイズ', value: formatFileSize(video.sizeBytes)),
      (label: '他のデバイスに転送', value: video.isPlayable ? '対応' : '--'),
      (label: '保存場所', value: _storageLocation(video)),
      (label: '位置情報', value: '--'),
      (label: '動画', value: _videoDescription(video)),
      (label: '音声', value: _audioDescription(video)),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
      itemCount: rows.length,
      separatorBuilder: (_, index) => SizedBox(
        height: switch (index) {
          5 => 64,
          6 => 58,
          _ => 27,
        },
      ),
      itemBuilder: (context, index) {
        final row = rows[index];
        return _DetailRow(label: row.label, value: row.value);
      },
    );
  }

  String _storageLocation(Video video) {
    final path = video.relativePath?.trim();
    if (path != null && path.isNotEmpty) {
      return path;
    }
    return video.folderName.trim().isEmpty ? '--' : video.folderName;
  }

  String _videoDescription(Video video) {
    final values = <String>[
      _containerFormat(video),
      formatResolution(
        width: video.width,
        height: video.height,
        rotationDegrees: video.rotationDegrees,
      ),
      formatDuration(video.duration),
      formatFrameRate(video.frameRate),
      _friendlyCodec(video.videoCodec),
      formatBitrate(video.bitrate),
    ].where(_isKnown).toList(growable: false);
    return values.isEmpty ? '--' : values.join(' / ');
  }

  String _audioDescription(Video video) {
    final values = <String>[
      _channelDescription(video.audioChannelCount),
      _friendlyCodec(video.audioCodec),
    ].where(_isKnown).toList(growable: false);
    return values.isEmpty ? '--' : values.join(' / ');
  }

  bool _isKnown(String value) => value != '--' && value != '--:--';

  String _containerFormat(Video video) {
    final dot = video.displayName.lastIndexOf('.');
    if (dot >= 0 && dot < video.displayName.length - 1) {
      return video.displayName.substring(dot + 1).toUpperCase();
    }
    final mime = video.mimeType;
    if (mime == null || mime.isEmpty) return '--';
    return mime.split('/').last.toUpperCase();
  }

  String _friendlyCodec(String? mimeType) {
    return switch (mimeType?.toLowerCase()) {
      'video/avc' => 'H.264',
      'video/hevc' => 'H.265 / HEVC',
      'video/x-vnd.on2.vp8' => 'VP8',
      'video/x-vnd.on2.vp9' => 'VP9',
      'video/av01' => 'AV1',
      'audio/mp4a-latm' => 'AAC',
      'audio/mpeg' => 'MP3',
      'audio/opus' => 'Opus',
      'audio/vorbis' => 'Vorbis',
      final String value when value.isNotEmpty => value,
      _ => '--',
    };
  }

  String _channelDescription(int? channelCount) {
    return switch (channelCount) {
      1 => 'mono',
      2 => 'stereo',
      final int count when count > 0 => '$count ch',
      _ => '--',
    };
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: label == '他のデバイスに転送'
              ? SizedBox(
                  height: 24,
                  child: FittedBox(
                    alignment: Alignment.topLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(label, style: _labelStyle),
                  ),
                )
              : Text(
                  label,
                  style: _labelStyle,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Color(0xFFE9EAEC),
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  static const _labelStyle = TextStyle(
    color: Color(0xFF969AA2),
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );
}
