import 'dart:typed_data';

void downloadBytes({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError('Browser file download is only supported on Flutter Web.');
}
