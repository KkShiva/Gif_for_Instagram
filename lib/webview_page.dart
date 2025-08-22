import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  static const _channel = MethodChannel('ffmpeg'); // ✅ platform channel

  late final WebViewController _controller;
  File? _downloadedFile;
  File? _convertedVideo; // store MP4 result
  double? _progress; // null = idle, 0-1 = downloading
  String _statusMessage = ""; // top status message

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel("ImageChannel",
          onMessageReceived: (message) async {
        String url = message.message;
        await _downloadImage(url);
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            await _injectLongPressScript();
          },
        ),
      )
      ..loadRequest(
          Uri.parse("https://duckduckgo.com/?q=dog+gif&iax=images&ia=images"));
  }

  Future<void> _injectLongPressScript() async {
    await _controller.runJavaScript('''
      document.addEventListener("contextmenu", function(event) {
        let target = event.target;
        if(target.tagName === "IMG"){
          ImageChannel.postMessage(target.src);
          event.preventDefault();
        }
      });
    ''');
  }

  Future<void> _downloadImage(String url) async {
    try {
      setState(() {
        _progress = 0;
        _statusMessage = "Download started…";
        _convertedVideo = null;
      });

      final response =
          await http.Client().send(http.Request('GET', Uri.parse(url)));

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/shared_image.gif");
      final sink = file.openWrite();

      final total = response.contentLength ?? 0;
      int received = 0;

      await for (var chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);

        if (total > 0) {
          final progress = received / total;
          setState(() {
            _progress = progress;
            _statusMessage =
                "Downloading… ${(progress * 100).toStringAsFixed(0)}%";
          });
        }
      }
      await sink.close();

      setState(() {
        _downloadedFile = file;
        _progress = null;
        _statusMessage = "Download complete. Converting to video…";
      });

      // Convert GIF to MP4 via platform channel
      await _convertGifToMp4(file);
    } catch (e) {
      debugPrint("Download failed: $e");
      setState(() {
        _progress = null;
        _statusMessage = "Download failed!";
      });
    }
  }

  Future<void> _convertGifToMp4(File gifFile) async {
    final dir = await getTemporaryDirectory();
    final outPath =
        '${dir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command =
        "-y -i ${gifFile.path} -movflags faststart -pix_fmt yuv420p $outPath";

    try {
      await _channel.invokeMethod('execute', {"command": command});

      setState(() {
        _convertedVideo = File(outPath);
        _statusMessage = "Video ready to share!";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("GIF converted to video")),
      );
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = "Conversion failed!";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("FFmpeg execution failed: ${e.message}")),
      );
    }
  }

  void _shareFile() {
    if (_convertedVideo != null) {
      Share.shareXFiles([XFile(_convertedVideo!.path)],
          text: "Check out this video!");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No video available yet")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GIF For Insta - Hold to Download"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareFile,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Column(
            children: [
              if (_progress != null) LinearProgressIndicator(value: _progress),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0), fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
