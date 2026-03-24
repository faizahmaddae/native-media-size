import 'dart:io';

import 'package:flutter/services.dart';

/// Query file sizes for photo/video assets from the OS media database.
///
/// Uses MediaStore on Android and PHAssetResource on iOS to return byte
/// counts without copying files to the app sandbox.
///
/// **Platform reliability:**
/// - **Android** — Exact. Reads `MediaStore.MediaColumns.SIZE`, an official
///   column backed by the OS file index.
/// - **iOS** — Best-effort. Reads `PHAssetResource.value(forKey: "fileSize")`,
///   an undocumented key. Values are accurate in practice, but Apple does not
///   guarantee this key across OS versions. If it ever stops working, the
///   plugin will return `null` for affected assets.
///
/// Use [isExact] to check which tier the current platform falls into.
///
/// Asset IDs are compatible with `photo_manager`'s `AssetEntity.id`.
class NativeMediaSize {
  static const _channel = MethodChannel('native_media_size');

  NativeMediaSize._();

  /// Whether sizes returned on this platform are guaranteed exact.
  ///
  /// `true` on Android (official MediaStore column).
  /// `false` on iOS (undocumented PHAssetResource key — accurate but
  /// not guaranteed by Apple).
  static bool get isExact => Platform.isAndroid;

  /// Get the file size in bytes for a single asset.
  ///
  /// Returns `null` if the asset was not found or size could not be determined.
  /// On iOS, a non-null result is a best-effort estimate (see [isExact]).
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
  ///
  /// On iOS, values are best-effort estimates (see [isExact]).
  static Future<Map<String, int>> getFileSizes(List<String> assetIds) async {
    if (assetIds.isEmpty) return {};
    final result = await _channel.invokeMethod<Map>('getFileSizes', {
      'assetIds': assetIds,
    });
    if (result == null) return {};
    return result.map((key, value) => MapEntry(key as String, value as int));
  }
}
