import 'package:flutter/services.dart';

/// Thin clipboard abstraction so ViewModels stay testable and Views avoid
/// direct `flutter/services.dart` coupling.
class ClipboardService {
  const ClipboardService();

  Future<void> copyText(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}
