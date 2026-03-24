/// Query file sizes for photo/video assets directly from the OS media
/// database without copying files to the app sandbox.
///
/// Works with asset IDs from the `photo_manager` package.
library native_media_size;

export 'src/native_media_size_channel.dart' show NativeMediaSize;
