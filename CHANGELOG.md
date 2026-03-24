# Changelog

## 0.1.0

- Initial release.
- `getFileSize(String assetId)` — single asset file size query.
- `getFileSizes(List<String> assetIds)` — batch query for multiple assets.
- Android: Uses MediaStore `_size` column via ContentResolver.
- iOS: Uses PHAssetResource `fileSize` key via Photos framework.
