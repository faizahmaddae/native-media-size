import 'package:flutter/services.dart';

/// Query file sizes for photo/video assets from the OS media database.
///
/// Uses MediaStore on Android and PHAssetResource on iOS to return exact
/// byte counts without copying files to the app sandbox.
///
/// Asset IDs are compatible with `photo_manager`'s `AssetEntity.id`.
class NativeMediaSize {
  static const _channel = MethodChannel('native_media_size');

  NativeMediaSize._();

  /// Get the file size in bytes for a single asset.
  ///
  /// Returns `null` if the asset was not found or size could not be determined.
  static Future<int?> getFileSize(String assetId) async {
    final result = await _channel.invokeMethod<int>('getFileSize', {
      'assetId': assetId,
    });
    return result;
  }

  /// Get file sizes in bytes for multiple assets in a single platform call.
  ///
  /// Returns a map of `assetId → sizeInBytes`. Assets whose sizes could not
  /// be determined are omitted from the result.
  ///
  /// This is significantly faster than calling [getFileSize] in a loop because
  /// it makes a single platform channel round-trip.
  static Future<Map<String, int>> getFileSizes(List<String> assetIds) async {
    if (assetIds.isEmpty) return {};
    final result = await _channel.invokeMethod<Map>('getFileSizes', {
      'assetIds': assetIds,
    });
    if (result == null) return {};
    return result.map((key, value) => MapEntry(key as String, value as int));
  }
}
