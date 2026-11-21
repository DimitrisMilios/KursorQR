import 'package:firebase_core/firebase_core.dart';

/// Application-wide constants and Firebase Spark Plan configuration.
class AppConfig {
  const AppConfig._();

  static const String appName = 'KursorQR';
  static const String redirectBaseUrl = 'https://kursorqr.web.app/r';
  static const String qrLinksCollection = 'qr_links';
  static const String usersCollection = 'users';

  /// Hard server-enforced limit per free account (matched in `firestore.rules`).
  static const int maxQrLinksPerAccount = 10;

  /// Max local custom logo file size in bytes (2 MB, processed strictly in browser memory).
  static const int maxLocalLogoBytes = 2 * 1024 * 1024;

  /// Firebase Spark Plan Web SDK configuration for `kursorqr`.
  static const FirebaseOptions firebaseWebOptions = FirebaseOptions(
    apiKey: 'AIzaSyDxcSD5L1rG5yIKPJkhXNvvp-VR0FwIsaA',
    appId: '1:212947339529:web:6b27aba595ea67ab54abd8',
    messagingSenderId: '212947339529',
    projectId: 'kursorqr',
    authDomain: 'kursorqr.firebaseapp.com',
    storageBucket: 'kursorqr.firebasestorage.app',
  );
}
