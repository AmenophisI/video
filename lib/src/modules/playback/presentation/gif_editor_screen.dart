import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image_codec;

import '../../../shared/utils/duration_format.dart';
import '../../video/domain/video.dart';
import '../data/player_system_adapter.dart';

class GifEditorScreen extends StatefulWidget {
  const GifEditorScreen({
    required this.video,
    required this.initialPosition,
    required this.videoDuration,
    super.key,
  });

  final Video video;
  final Duration initialPosition;
  final Duration videoDuration;

  @override
  State<GifEditorScreen> createState() => _GifEditorScreenState();
}

class _GifEditorScreenState extends State<GifEditorScreen> {
  static const PlayerSystemAdapter _systemAdapter = PlayerSystemAdapter();
  static const Duration _selectionDuration = Duration(seconds: 4);

  late double _startSeconds;
  double _speed = 1;
  bool _isGenerating = false;
  Uint8List? _gifBytes;
  String? _error;

  double get _videoSeconds => widget.videoDuration.inMilliseconds <= 0
      ? 4
      : widget.videoDuration.inMilliseconds / 1000;

  double get _rangeSeconds =>
      _videoSeconds.clamp(0.2, _selectionDuration.inSeconds.toDouble());

  double get _maxStart =>
      (_videoSeconds - _rangeSeconds).clamp(0, double.infinity);

  Duration get _start => Duration(milliseconds: (_startSeconds * 1000).round());

  Duration get _range => Duration(milliseconds: (_rangeSeconds * 1000).round());

  @override
  void initState() {
    super.initState();
    _startSeconds = (widget.initialPosition.inMilliseconds / 1000)
        .clamp(0, _maxStart)
        .toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generatePreview());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('GIFを作成'),
        actions: [
          IconButton(
            tooltip: '共有',
            onPressed: _gifBytes == null || _isGenerating ? null : _share,
            icon: const Icon(Icons.share_outlined),
          ),
          TextButton(
            onPressed: _gifBytes == null || _isGenerating ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            AspectRatio(
              aspectRatio: _previewAspectRatio(widget.video),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildPreview(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatDuration(_start)}〜${formatDuration(_start + _range)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  '${_rangeSeconds.toStringAsFixed(1)}秒',
                  style: const TextStyle(
                    color: Color(0xFF6EA8FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: _startSeconds.clamp(0, _maxStart),
              max: _maxStart <= 0 ? 1 : _maxStart,
              onChanged: _maxStart <= 0 || _isGenerating
                  ? null
                  : (value) {
                      setState(() {
                        _startSeconds = value;
                        _gifBytes = null;
                      });
                    },
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _isGenerating
                      ? null
                      : () {
                          setState(() {
                            _startSeconds = 0;
                            _gifBytes = null;
                          });
                          _generatePreview();
                        },
                  icon: const Icon(Icons.first_page),
                  label: const Text('最初から'),
                ),
                const Spacer(),
                const Text('速度', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 10),
                DropdownButton<double>(
                  value: _speed,
                  dropdownColor: const Color(0xFF272727),
                  style: const TextStyle(color: Colors.white),
                  onChanged: _isGenerating
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _speed = value;
                            _gifBytes = null;
                          });
                        },
                  items: const [
                    DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                    DropdownMenuItem(value: 1, child: Text('1.0x')),
                    DropdownMenuItem(value: 2, child: Text('2.0x')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generatePreview,
              icon: const Icon(Icons.refresh),
              label: Text(_gifBytes == null ? 'プレビューを作成' : 'プレビューを更新'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isGenerating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('GIFを作成中…', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
    final bytes = _gifBytes;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
      );
    }
    return const Center(
      child: Icon(Icons.gif_box_outlined, size: 56, color: Colors.white38),
    );
  }

  Future<void> _generatePreview() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final frames = await _systemAdapter.extractFrames(
        videoUri: widget.video.uri,
        start: _start,
        duration: _range,
      );
      final bytes = await compute(_encodeGif, <String, Object>{
        'frames': frames,
        'durationMs': _range.inMilliseconds,
        'speed': _speed,
      });
      if (!mounted) return;
      setState(() {
        _gifBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'GIFを作成できませんでした: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final bytes = _gifBytes;
    if (bytes == null) return;
    try {
      await _systemAdapter.saveGif(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GIFを保存しました')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GIFを保存できませんでした: $error')),
        );
      }
    }
  }

  Future<void> _share() async {
    final bytes = _gifBytes;
    if (bytes == null) return;
    try {
      await _systemAdapter.shareGif(bytes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GIFを共有できませんでした: $error')),
        );
      }
    }
  }

  double _previewAspectRatio(Video video) {
    final width = video.width;
    final height = video.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return 16 / 9;
    }
    return width / height;
  }
}

Uint8List _encodeGif(Map<String, Object> request) {
  final frames = request['frames']! as List<Uint8List>;
  final durationMs = request['durationMs']! as int;
  final speed = request['speed']! as double;
  final frameDelay =
      (durationMs / frames.length / speed / 10).round().clamp(2, 200);
  final encoder = image_codec.GifEncoder(
    repeat: 0,
    numColors: 128,
    samplingFactor: 15,
  );
  for (final bytes in frames) {
    final decoded = image_codec.decodeJpg(bytes);
    if (decoded == null) continue;
    final resized = decoded.width > 480
        ? image_codec.copyResize(decoded, width: 480)
        : decoded;
    encoder.addFrame(resized, duration: frameDelay);
  }
  final result = encoder.finish();
  if (result == null || result.isEmpty) {
    throw StateError('GIF encoding failed.');
  }
  return result;
}
