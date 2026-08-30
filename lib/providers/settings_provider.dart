import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Central place for all user configurable app settings.
/// Persists values using SharedPreferences so they survive app restarts.
class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode'; // 0 = system, 1 = light, 2 = dark
  static const _kGestureControl = 'gesture_control';
  static const _kAutoplayNext = 'autoplay_next';

  ThemeMode _themeMode = ThemeMode.system;
  bool _gestureControl = true;
  bool _autoplayNext = false;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  bool get gestureControl => _gestureControl;
  bool get autoplayNext => _autoplayNext;
  bool get loaded => _loaded;

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_kThemeMode) ?? 0;
    _themeMode = ThemeMode.values[modeIndex];
    _gestureControl = prefs.getBool(_kGestureControl) ?? true;
    _autoplayNext = prefs.getBool(_kAutoplayNext) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setGestureControl(bool value) async {
    _gestureControl = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGestureControl, value);
  }

  Future<void> setAutoplayNext(bool value) async {
    _autoplayNext = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAutoplayNext, value);
  }
}
