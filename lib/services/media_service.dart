import 'package:photo_manager/photo_manager.dart';

/// Wraps photo_manager calls to scan the device for all images & videos.
class MediaService {
  /// Fetches every image and video on the device across all albums,
  /// sorted newest first.
  static Future<List<AssetEntity>> fetchAllMedia() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) {
      return [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      ),
    );

    if (albums.isEmpty) return [];

    final recentAlbum = albums.first;
    final count = await recentAlbum.assetCountAsync;
    final assets = await recentAlbum.getAssetListRange(start: 0, end: count);
    return assets;
  }

  static List<AssetEntity> filterPhotos(List<AssetEntity> assets) =>
      assets.where((a) => a.type == AssetType.image).toList();

  static List<AssetEntity> filterVideos(List<AssetEntity> assets) =>
      assets.where((a) => a.type == AssetType.video).toList();
}
