import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';
import 'permission_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Small delay so the branding is visible, then check permissions.
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final photoStatus = await Permission.photos.status;
    final videoStatus = await Permission.videos.status;
    final storageStatus = await Permission.storage.status;

    final granted = photoStatus.isGranted ||
        videoStatus.isGranted ||
        storageStatus.isGranted;

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => granted ? const HomeScreen() : const PermissionScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E12) : Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, Color(0xFF9C88FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  'Gallery',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
