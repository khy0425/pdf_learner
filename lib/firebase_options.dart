import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return windows;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static final FirebaseOptions windows = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
    appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
    authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
    storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'] ?? '',
  );
} 