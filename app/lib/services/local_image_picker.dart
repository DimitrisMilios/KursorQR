import 'dart:typed_data';

import 'local_image_picker_stub.dart'
    if (dart.library.js_interop) 'local_image_picker_web.dart' as impl;

/// Result of picking a local logo image strictly in browser memory (never uploaded).
class PickedLocalImage {
  const PickedLocalImage({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

/// Opens the native browser file picker for PNG/JPG/WebP images and returns
/// raw bytes in memory. Returns `null` if the user cancels.
Future<PickedLocalImage?> pickLocalLogoImage({required int maxBytes}) {
  return impl.pickLocalLogoImage(maxBytes: maxBytes);
}
