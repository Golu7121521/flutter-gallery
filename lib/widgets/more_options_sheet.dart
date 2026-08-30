import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';
import 'package:intl/intl.dart';

/// Bottom sheet with: Set as wallpaper, Details.
Future<void> showMoreOptionsSheet(BuildContext context, AssetEntity asset) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoreOptionsSheet(asset: asset),
  );
}

class _MoreOptionsSheet extends StatelessWidget {
  final AssetEntity asset;
  const _MoreOptionsSheet({required this.asset});

  Future<void> _setWallpaper(BuildContext context) async {
    Navigator.pop(context);
    if (asset.type != AssetType.image) {
      _snack(context, 'Only images can be set as wallpaper');
      return;
    }
    final file = await asset.file;
    if (file == null) return;
    try {
      final result = await WallpaperManagerFlutter().setWallpaper(
        file,
        WallpaperManagerFlutter.homeScreen,
      );
      _snack(context, result == true ? 'Wallpaper set' : 'Failed to set wallpaper');
    } catch (e) {
      _snack(context, 'Failed to set wallpaper');
    }
  }

  Future<void> _showDetails(BuildContext context) async {
    Navigator.pop(context);
    final file = await asset.file;
    final sizeBytes = await file?.length() ?? 0;
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('Name', asset.title ?? 'Unknown'),
            _DetailRow('Type', asset.type == AssetType.video ? 'Video' : 'Image'),
            _DetailRow('Created', DateFormat('d MMM yyyy, h:mm a').format(asset.createDateTime)),
            _DetailRow('Dimensions', '${asset.width} x ${asset.height}'),
            _DetailRow('Size', '$sizeMb MB'),
            if (asset.type == AssetType.video)
              _DetailRow('Duration', '${asset.videoDuration.inSeconds}s'),
            _DetailRow('Path', file?.path ?? 'Unknown'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

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
              leading: const Icon(Icons.wallpaper_rounded),
              title: const Text('Set as wallpaper'),
              onTap: () => _setWallpaper(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Details'),
              onTap: () => _showDetails(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
