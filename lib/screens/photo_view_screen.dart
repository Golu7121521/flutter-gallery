import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_cropper/image_cropper.dart';

import '../providers/favorites_provider.dart';
import '../providers/trash_provider.dart';
import '../widgets/viewer_action_bar.dart';
import '../widgets/more_options_sheet.dart';
import '../widgets/delete_confirm_dialog.dart';
import 'draw_screen.dart';

class PhotoViewScreen extends StatefulWidget {
  final List<AssetEntity> assets;
  final int initialIndex;

  const PhotoViewScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
  });

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  late int _index;
  bool _chromeVisible = true;
  late PageController _pageController;

  AssetEntity get _current => widget.assets[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  Future<void> _share() async {
    final file = await _current.file;
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  Future<void> _edit() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditOptionsSheet(),
    );
    if (choice == null) return;
    final file = await _current.file;
    if (file == null) return;

    if (choice == 'crop') {
      final cropped = await ImageCropper().cropImage(
        sourcePath: file.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop'),
        ],
      );
      if (cropped != null) {
        await PhotoManager.editor.saveImageWithPath(cropped.path, title: '${_current.title}_cropped.jpg');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cropped image saved to gallery')),
          );
        }
      }
    } else if (choice == 'draw') {
      final bytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(builder: (_) => DrawScreen(imageFile: file)),
      );
      if (bytes != null) {
        await PhotoManager.editor.saveImage(
          bytes,
          filename: '${_current.title}_drawn.png',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Drawing saved to gallery')),
          );
        }
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed) return;
    final trash = context.read<TrashProvider>();
    trash.addToTrash(_current);
    await PhotoManager.editor.deleteWithIds([_current.id]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleChrome,
            child: PhotoViewGallery.builder(
              pageController: _pageController,
              itemCount: widget.assets.length,
              onPageChanged: (i) => setState(() => _index = i),
              builder: (context, i) {
                final asset = widget.assets[i];
                return PhotoViewGalleryPageOptions(
                  imageProvider: AssetEntityImageProvider(asset),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(tag: 'media_${asset.id}'),
                );
              },
              loadingBuilder: (context, event) =>
                  const Center(child: CircularProgressIndicator()),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
          if (_chromeVisible)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_chromeVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ViewerActionBar(
                onShare: _share,
                onEdit: _edit,
                onFavorite: () => favorites.toggle(_current.id),
                isFavorite: favorites.isFavorite(_current.id),
                onDelete: _delete,
                onMore: () => showMoreOptionsSheet(context, _current),
              ),
            ),
        ],
      ),
    );
  }
}

/// A minimal ImageProvider implementation that loads full-resolution
/// bytes from an AssetEntity for use with PhotoView.
class AssetEntityImageProvider extends ImageProvider<AssetEntityImageProvider> {
  final AssetEntity asset;
  const AssetEntityImageProvider(this.asset);

  @override
  Future<AssetEntityImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetEntityImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      AssetEntityImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(ImageDecoderCallback decode) async {
    final bytes = await asset.originBytes;
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes!);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is AssetEntityImageProvider && other.asset.id == asset.id;

  @override
  int get hashCode => asset.id.hashCode;
}

class _EditOptionsSheet extends StatelessWidget {
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
              leading: const Icon(Icons.crop_rounded),
              title: const Text('Crop'),
              onTap: () => Navigator.pop(context, 'crop'),
            ),
            ListTile(
              leading: const Icon(Icons.draw_rounded),
              title: const Text('Draw'),
              onTap: () => Navigator.pop(context, 'draw'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
