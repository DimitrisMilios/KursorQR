import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';

export 'app.dart' show KursorQrApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;
  try {
    await Firebase.initializeApp(options: AppConfig.firebaseWebOptions);
  } catch (e) {
    initError = e.toString();
  }

  runApp(KursorQrApp(initError: initError));
}
