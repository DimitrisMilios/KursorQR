import 'dart:typed_data';

void downloadPngBytes(Uint8List bytes, String fileName) {
  throw UnsupportedError(
    'Direct browser PNG download is only supported on Flutter Web.',
  );
}
