import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart';
import '../theme/app_theme.dart';

/// Shown when the app does not yet have access to media on the device.
/// Explains why access is needed and lets the user grant it, or open
/// system settings if they previously denied permanently.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _requesting = false;

  Future<void> _requestAccess() async {
    setState(() => _requesting = true);
    final statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.storage,
    ].request();

    final granted = statuses.values.any((s) => s.isGranted);
    setState(() => _requesting = false);

    if (!mounted) return;
    if (granted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (statuses.values.any((s) => s.isPermanentlyDenied)) {
      _showSettingsDialog();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission needed'),
        content: const Text(
          'Gallery needs access to your photos and videos to work. '
          'Please enable it from app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.perm_media_rounded,
                  size: 90, color: AppTheme.accent),
              const SizedBox(height: 24),
              Text(
                'Access your photos & videos',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Gallery scans your device to show all your photos and '
                'videos neatly organised. We never upload your media anywhere.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _requesting ? null : _requestAccess,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Grant Access'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
