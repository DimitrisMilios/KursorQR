import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart' as impl;

/// Triggers a PNG file download in the browser on Flutter Web.
void downloadPngBytes(Uint8List bytes, String fileName) {
  impl.downloadPngBytes(bytes, fileName);
}
