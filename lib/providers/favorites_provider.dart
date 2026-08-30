import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks favorite media items by their AssetEntity id.
class FavoritesProvider extends ChangeNotifier {
  static const _kKey = 'favorite_ids';
  final Set<String> _ids = {};

  FavoritesProvider() {
    _load();
  }

  bool isFavorite(String id) => _ids.contains(id);

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kKey) ?? [];
    _ids.addAll(list);
    notifyListeners();
  }

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kKey, _ids.toList());
  }
}
