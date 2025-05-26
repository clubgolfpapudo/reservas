// ============================================================================
// ARCHIVO 1: lib/firebase_options.dart (CREAR ESTE ARCHIVO)
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDdXsf0ZxA8IS7GD9pDAnAwkJFOsq6YVRE',
    appId: '1:577498054078:web:fb7b12b9e355065d3d0def',
    messagingSenderId: '577498054078',
    projectId: 'cgpreservas',
    authDomain: 'cgpreservas.firebaseapp.com',
    storageBucket: 'cgpreservas.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdXsf0ZxA8IS7GD9pDAnAwkJFOsq6YVRE',
    appId: '1:577498054078:android:your_android_app_id',
    messagingSenderId: '577498054078',
    projectId: 'cgpreservas',
    storageBucket: 'cgpreservas.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdXsf0ZxA8IS7GD9pDAnAwkJFOsq6YVRE',
    appId: '1:577498054078:ios:your_ios_app_id',
    messagingSenderId: '577498054078',
    projectId: 'cgpreservas',
    storageBucket: 'cgpreservas.firebasestorage.app',
    iosBundleId: 'com.cgp.reservas',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDdXsf0ZxA8IS7GD9pDAnAwkJFOsq6YVRE',
    appId: '1:577498054078:macos:your_macos_app_id',
    messagingSenderId: '577498054078',
    projectId: 'cgpreservas',
    storageBucket: 'cgpreservas.firebasestorage.app',
    iosBundleId: 'com.cgp.reservas',
  );
}