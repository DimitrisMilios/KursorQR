import 'dart:typed_data';

import 'file_downloader_stub.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart' as impl;

/// Triggers a binary file download (e.g. PNG) in the browser on Flutter Web.
void downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  impl.downloadBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
}
