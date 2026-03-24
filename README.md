# native_media_size

Query file sizes for photo/video assets directly from the OS media database — **no file copying, no sandbox I/O**.

## The problem

Flutter's `photo_manager` package doesn't expose file sizes on `AssetEntity`. The common workaround:

```dart
final file = await asset.file;       // copies entire file to app sandbox
final bytes = await file.length();   // stats the copied file
```

This is **extremely slow** for bulk operations (scanning hundreds/thousands of assets) and causes UI lag because each call triggers a full file copy through the platform channel.

## The solution

`native_media_size` queries the OS media database directly:

- **Android**: `MediaStore.MediaColumns.SIZE` — a SQLite column, instant lookup
- **iOS**: `PHAssetResource.value(forKey: "fileSize")` — Photos framework metadata

Returns byte counts with near-zero latency and no file I/O.

## Platform differences

| | Android | iOS |
|---|---|---|
| **Source** | `MediaStore.MediaColumns.SIZE` | `PHAssetResource.value(forKey: "fileSize")` |
| **API status** | Official, stable | Undocumented key — works as of iOS 18 |
| **Accuracy** | Exact | Accurate in practice, not guaranteed by Apple |
| **Risk** | None | Apple may remove the key in a future iOS version |
| **Failure mode** | N/A | Returns `null` — callers should handle gracefully |

Use `NativeMediaSize.isExact` at runtime to check which tier applies:

```dart
if (NativeMediaSize.isExact) {
  // Android — sizes are guaranteed exact
} else {
  // iOS — sizes are best-effort, handle null gracefully
}
```

**Why not use an official iOS API?**

Apple's `PHAssetResourceManager.requestData` is the only official way to determine file size, but it requires reading the full file data — which defeats the purpose of a fast metadata query. The undocumented key is a deliberate trade-off: near-instant performance vs. long-term API stability.

## Usage

```dart
import 'package:native_media_size/native_media_size.dart';

// Single asset
final size = await NativeMediaSize.getFileSize(asset.id);
if (size != null) {
  print('$size bytes');
}

// Batch query (recommended for bulk operations)
final ids = assets.map((a) => a.id).toList();
final sizes = await NativeMediaSize.getFileSizes(ids);
// sizes: {'asset_id_1': 4521039, 'asset_id_2': 2103948, ...}
// Assets whose sizes could not be determined are omitted.
```

## Performance comparison

| Approach | 1000 photos | I/O |
|---|---|---|
| `asset.file` + `file.length()` | ~30-60 seconds | Copies every file |
| `NativeMediaSize.getFileSizes()` | < 100ms | Zero file I/O |

## Requirements

- **Android**: API 21+
- **iOS**: 12.0+
- Photo library permission must be granted before querying

## Compatibility

Works with asset IDs from the `photo_manager` package (`AssetEntity.id`).
