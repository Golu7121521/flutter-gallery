import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

import '../screens/photo_view_screen.dart';
import '../screens/video_view_screen.dart';

/// Displays a list of [AssetEntity] grouped by date (newest first) in a
/// responsive thumbnail grid, similar to most stock gallery apps.
class MediaGrid extends StatelessWidget {
  final List<AssetEntity> assets;
  final bool showVideoDuration;

  const MediaGrid({
    super.key,
    required this.assets,
    this.showVideoDuration = true,
  });

  Map<String, List<AssetEntity>> _groupByDate() {
    final Map<String, List<AssetEntity>> groups = {};
    for (final asset in assets) {
      final date = asset.createDateTime;
      final key = DateFormat('EEEE, d MMMM yyyy').format(date);
      groups.putIfAbsent(key, () => []).add(asset);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined,
                size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 12),
            Text('No media found', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    final groups = _groupByDate();
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 110),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final items = groups[key]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                key,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _ThumbnailTile(
                  asset: items[i],
                  allAssets: assets,
                  showDuration: showVideoDuration,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  final AssetEntity asset;
  final List<AssetEntity> allAssets;
  final bool showDuration;

  const _ThumbnailTile({
    required this.asset,
    required this.allAssets,
    required this.showDuration,
  });

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = asset.type == AssetType.video;

    return GestureDetector(
      onTap: () {
        final index = allAssets.indexOf(asset);
        if (isVideo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoViewScreen(
                assets: allAssets.where((a) => a.type == AssetType.video).toList(),
                initialIndex: allAssets
                    .where((a) => a.type == AssetType.video)
                    .toList()
                    .indexOf(asset),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoViewScreen(
                assets: allAssets,
                initialIndex: index,
              ),
            ),
          );
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'media_${asset.id}',
            child: AssetEntityImage(
              asset,
              isOriginal: false,
              thumbnailSize: const ThumbnailSize.square(250),
              fit: BoxFit.cover,
            ),
          ),
          if (isVideo)
            Positioned(
              right: 4,
              bottom: 4,
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 16),
                  if (showDuration) ...[
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(asset.videoDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Small helper to build an image widget straight from an AssetEntity's
/// thumbnail/original data.
class AssetEntityImage extends StatelessWidget {
  final AssetEntity asset;
  final bool isOriginal;
  final ThumbnailSize thumbnailSize;
  final BoxFit fit;

  const AssetEntityImage(
    this.asset, {
    super.key,
    this.isOriginal = false,
    this.thumbnailSize = const ThumbnailSize.square(250),
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: isOriginal
          ? asset.originBytes
          : asset.thumbnailDataWithSize(thumbnailSize),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(
            snapshot.data as dynamic,
            fit: fit,
            gaplessPlayback: true,
          );
        }
        return Container(color: Colors.grey.withOpacity(0.15));
      },
    );
  }
}
