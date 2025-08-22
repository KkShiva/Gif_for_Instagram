import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class GifToVideoPage extends StatefulWidget {
  final File gifFile;

  const GifToVideoPage({super.key, required this.gifFile});

  @override
  State<GifToVideoPage> createState() => _GifToVideoPageState();
}

class _GifToVideoPageState extends State<GifToVideoPage> {
  static const _channel = MethodChannel('ffmpeg');

  String? _outputPath;
  bool _isConverting = false;
  VideoPlayerController? _controller;

  Future<void> _convertGifToMp4() async {
    setState(() => _isConverting = true);

    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command =
        "-y -i ${widget.gifFile.path} -movflags faststart -pix_fmt yuv420p $outPath";

    try {
      await _channel.invokeMethod('execute', {"command": command});

      setState(() {
        _outputPath = outPath;
        _isConverting = false;
      });

      _controller = VideoPlayerController.file(File(outPath))
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    } on PlatformException catch (e) {
      setState(() => _isConverting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("FFmpeg execution failed: ${e.message}")),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GIF to Video")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isConverting) const CircularProgressIndicator(),
            if (!_isConverting && _outputPath == null)
              ElevatedButton(
                onPressed: _convertGifToMp4,
                child: const Text("Convert GIF to MP4"),
              ),
            if (_outputPath != null &&
                _controller != null &&
                _controller!.value.isInitialized)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
          ],
        ),
      ),
      floatingActionButton: _outputPath != null
          ? FloatingActionButton(
              onPressed: () {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
                setState(() {});
              },
              child: Icon(_controller!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow),
            )
          : null,
    );
  }
}
