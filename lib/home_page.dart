import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = "Long press any image or GIF to share";
  List<String> imageUrls = [
    "https://media.giphy.com/media/l0MYt5jPR6QX5pnqM/giphy.gif",
    "https://media.giphy.com/media/3o6Zt481isNVuQI1l6/giphy.gif",
    "https://picsum.photos/300/200",
    "https://picsum.photos/400/250",
  ];

  Future<void> _downloadAndShare(String url) async {
    try {
      setState(() {
        _status = "Download started...";
      });

      // Download file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _status = "Download complete, preparing to share...";
        });

        Uint8List bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        String fileName = url.split('/').last;
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);

        setState(() {
          _status = "Download ready to share.";
        });

        // Share the file
        await Share.shareXFiles([XFile(file.path)], text: "Check this out!");
      } else {
        setState(() {
          _status = "Failed to download file.";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GIF/Image Viewer"),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share("Check out these cool images & GIFs!");
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black12,
            width: double.infinity,
            child: Text(
              _status,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                final url = imageUrls[index];
                return GestureDetector(
                  onLongPress: () => _downloadAndShare(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
