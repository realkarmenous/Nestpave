import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const NestpaveApp());
}

class NestpaveApp extends StatelessWidget {
  const NestpaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nestpave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}