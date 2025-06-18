import 'package:flutter/material.dart';
import 'package:tradepath/edu_path_splash_screen.dart';
import 'edu_path_screen.dart';

class EduPathEntryScreen extends StatefulWidget {
  const EduPathEntryScreen({Key? key}) : super(key: key);

  @override
  State<EduPathEntryScreen> createState() => _EduPathEntryScreenState();
}

class _EduPathEntryScreenState extends State<EduPathEntryScreen> {
  static const int splashMs = 2800;
  static const int extraMs = 3000;

  @override
  void initState() {
    super.initState();
    _startSplashAndLoad();
  }

  Future<void> _startSplashAndLoad() async {
    final start = DateTime.now();
    // Burada asıl yükleme işlemini başlat (ör. await fetchData();)
    await Future.delayed(const Duration(milliseconds: 1400)); // örnek yükleme
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    final minSplash = splashMs + extraMs;
    final remaining = minSplash - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EduPathScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const EduPathSplashScreen();
  }
} 