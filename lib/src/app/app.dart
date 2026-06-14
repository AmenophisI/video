import 'package:flutter/material.dart';

import '../modules/video/presentation/video_library_screen.dart';

class VideoLibraryApp extends StatelessWidget {
  const VideoLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: const VideoLibraryScreen(),
    );
  }
}
