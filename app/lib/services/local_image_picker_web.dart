import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'local_image_picker.dart';

Future<PickedLocalImage?> pickLocalLogoImage({required int maxBytes}) async {
  final completer = Completer<PickedLocalImage?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = 'image/png,image/jpeg,image/webp'
    ..style.display = 'none';

  void cleanup() {
    input.remove();
  }

  input.onchange = ((web.Event _) {
    final files = input.files;
    if (files == null || files.length == 0) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files.item(0);
    if (file == null) {
      cleanup();
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    if (file.size > maxBytes) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(
          ArgumentError(
            'Image is too large (${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB). '
            'Please choose a PNG, JPG, or WebP under ${(maxBytes / (1024 * 1024)).toStringAsFixed(0)} MB.',
          ),
        );
      }
      return;
    }

    final reader = web.FileReader();
    reader.onloadend = ((web.Event _) {
      cleanup();
      final result = reader.result;
      if (result == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final arrayBuffer = result as JSArrayBuffer;
      final bytes = Uint8List.view(arrayBuffer.toDart);
      if (!completer.isCompleted) {
        completer.complete(PickedLocalImage(bytes: bytes, fileName: file.name));
      }
    }).toJS;

    reader.onerror = ((web.Event _) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(StateError('Could not read the selected image file.'));
      }
    }).toJS;

    reader.readAsArrayBuffer(file);
  }).toJS;

  input.oncancel = ((web.Event _) {
    cleanup();
    if (!completer.isCompleted) completer.complete(null);
  }).toJS;

  web.document.body?.appendChild(input);
  input.click();
  return completer.future;
}
