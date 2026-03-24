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

Returns the **exact same byte count** as `file.length()`, but with near-zero latency and no file I/O.

## Usage

```dart
import 'package:native_media_size/native_media_size.dart';

// Single asset
final size = await NativeMediaSize.getFileSize(asset.id);
print('$size bytes');

// Batch query (recommended for bulk operations)
final ids = assets.map((a) => a.id).toList();
final sizes = await NativeMediaSize.getFileSizes(ids);
// sizes: {'asset_id_1': 4521039, 'asset_id_2': 2103948, ...}
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
