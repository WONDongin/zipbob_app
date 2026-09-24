import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const ZipbobApp());
}

class ZipbobApp extends StatelessWidget {
  const ZipbobApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '집밥픽',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEF7544)),
        scaffoldBackgroundColor: const Color(0xFFFFFAF5),
      ),
      home: const HomeScreen(),
    );
  }
}
