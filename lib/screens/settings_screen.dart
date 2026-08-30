import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader('Playback & Interaction'),
          SwitchListTile(
            title: const Text('Gesture control'),
            subtitle: const Text(
                'Swipe for volume/brightness, double tap to seek, hold for 2x speed'),
            value: settings.gestureControl,
            onChanged: settings.setGestureControl,
          ),
          SwitchListTile(
            title: const Text('Autoplay next video'),
            subtitle: const Text('Automatically play the next video when one finishes'),
            value: settings.autoplayNext,
            onChanged: settings.setAutoplayNext,
          ),
          const Divider(height: 32),
          _SectionHeader('Appearance'),
          RadioListTile<ThemeMode>(
            title: const Text('Follow system'),
            value: ThemeMode.system,
            groupValue: settings.themeMode,
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Light mode'),
            value: ThemeMode.light,
            groupValue: settings.themeMode,
            onChanged: (v) => settings.setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark mode'),
            value: ThemeMode.dark,
            groupValue: settings.themeMode,
            onChanged: (v) => settings.setThemeMode(v!),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
