import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.accent, Color(0xFF9C88FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Gallery',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const Center(child: Text('Version 1.0.0')),
          const SizedBox(height: 24),
          const Text(
            'Gallery is a fast, private photo and video viewer for your '
            'device. All your media is scanned and displayed locally — '
            'nothing is ever uploaded to any server.',
          ),
          const SizedBox(height: 24),
          Text('User Agreement',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'By using Gallery, you agree that:\n\n'
            '1. Gallery only accesses media stored locally on your device.\n'
            '2. Deleting a file inside Gallery removes it from your device '
            'permanently once you confirm the deletion.\n'
            '3. The app does not collect or transmit any personal data.\n'
            '4. You are responsible for keeping backups of media you care about.\n'
            '5. This app is provided as-is, without warranty of any kind.',
          ),
          const SizedBox(height: 24),
          Text('Privacy Policy',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Gallery does not collect, store, or share any of your personal '
            'data or media with third parties. All processing happens '
            'entirely on your device.',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text('Made with Flutter',
                style: TextStyle(color: Theme.of(context).disabledColor)),
          ),
        ],
      ),
    );
  }
}
