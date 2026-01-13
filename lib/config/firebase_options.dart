import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return web;
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4s9MGS9XULPQNCJkxI_O16Py6sv4dgm0',
    appId: '1:69971331728:web:98fd4d2f25903861aba615',
    messagingSenderId: '69971331728',
    projectId: 'flutter-ccc75',
    authDomain: 'flutter-ccc75.firebaseapp.com',
    storageBucket: 'flutter-ccc75.firebasestorage.app',
    measurementId: 'G-CWGJBTQFQ1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4s9MGS9XULPQNCJkxI_O16Py6sv4dgm0',
    appId: '1:69971331728:android:fd4d2f25903861aba615',
    messagingSenderId: '69971331728',
    projectId: 'flutter-ccc75',
    storageBucket: 'flutter-ccc75.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC4s9MGS9XULPQNCJkxI_O16Py6sv4dgm0',
    appId: '1:69971331728:ios:fd4d2f25903861aba615',
    messagingSenderId: '69971331728',
    projectId: 'flutter-ccc75',
    storageBucket: 'flutter-ccc75.firebasestorage.app',
    iosBundleId: 'com.tourease.tourease',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC4s9MGS9XULPQNCJkxI_O16Py6sv4dgm0',
    appId: '1:69971331728:macos:fd4d2f25903861aba615',
    messagingSenderId: '69971331728',
    projectId: 'flutter-ccc75',
    storageBucket: 'flutter-ccc75.firebasestorage.app',
    iosBundleId: 'com.tourease.tourease',
  );
}
