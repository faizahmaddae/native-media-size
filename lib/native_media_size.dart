/// Query file sizes for photo/video assets directly from the OS media
/// database without copying files to the app sandbox.
///
/// **Platform reliability:**
/// - Android: Exact sizes via official MediaStore column.
/// - iOS: Best-effort sizes via undocumented PHAssetResource key.
///
/// See [NativeMediaSize.isExact] for runtime detection.
///
/// Works with asset IDs from the `photo_manager` package.
library;

export 'src/native_media_size_channel.dart' show NativeMediaSize;
