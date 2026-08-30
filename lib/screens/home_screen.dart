import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/media_service.dart';
import '../providers/favorites_provider.dart';
import '../widgets/floating_tab_bar.dart';
import '../widgets/media_grid.dart';
import 'trash_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  bool _loading = true;
  List<AssetEntity> _allMedia = [];

  static const _titles = ['Recent', 'Photos', 'Videos', 'Favorites'];

  @override
  void initState() {
    super.initState();
    _scanMedia();
  }

  Future<void> _scanMedia() async {
    setState(() => _loading = true);
    final media = await MediaService.fetchAllMedia();
    if (!mounted) return;
    setState(() {
      _allMedia = media;
      _loading = false;
    });
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreMenuSheet(onRefresh: _scanMedia),
    );
  }

  List<AssetEntity> get _currentList {
    switch (_tabIndex) {
      case 1:
        return MediaService.filterPhotos(_allMedia);
      case 2:
        return MediaService.filterVideos(_allMedia);
      case 3:
        final favorites = context.watch<FavoritesProvider>();
        return _allMedia.where((a) => favorites.isFavorite(a.id)).toList();
      default:
        return _allMedia;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(_titles[_tabIndex],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _scanMedia,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Rescan device',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _scanMedia,
              child: MediaGrid(assets: _currentList),
            ),
      bottomNavigationBar: FloatingTabBar(
        currentIndex: _tabIndex,
        onTabSelected: (i) => setState(() => _tabIndex = i),
        onMenuTap: _openMenu,
      ),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  final VoidCallback onRefresh;
  const _MoreMenuSheet({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C22) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Trash bin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
