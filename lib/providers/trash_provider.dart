import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// Keeps track of items the user has moved to the in-app Trash bin.
/// Note: Actual permanent deletion happens through PhotoManager which
/// on most Android/iOS versions asks for a native confirmation itself.
/// This provider gives the app a "soft trash" UX layer on top of that.
class TrashItem {
  final AssetEntity asset;
  final DateTime deletedAt;

  TrashItem({required this.asset, required this.deletedAt});
}

class TrashProvider extends ChangeNotifier {
  final List<TrashItem> _items = [];

  List<TrashItem> get items => List.unmodifiable(_items);

  void addToTrash(AssetEntity asset) {
    _items.add(TrashItem(asset: asset, deletedAt: DateTime.now()));
    notifyListeners();
  }

  void restore(AssetEntity asset) {
    _items.removeWhere((e) => e.asset.id == asset.id);
    notifyListeners();
  }

  void removePermanently(AssetEntity asset) {
    _items.removeWhere((e) => e.asset.id == asset.id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
