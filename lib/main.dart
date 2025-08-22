import 'package:flutter/material.dart';
import 'webview_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GIF For Insta - Hold to Download',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const WebViewPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
