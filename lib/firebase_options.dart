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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBvy8hAaDHUseKZTJ6t49V8nuqIaWRfcLI",
    authDomain: "livework-be38f.firebaseapp.com",
    projectId: "livework-be38f",
    storageBucket: "livework-be38f.firebasestorage.app",
    messagingSenderId: "1032197181846",
    appId: "1:1032197181846:web:d7374cddc99495a0ab0db7",
    measurementId: "G-YHCEN9LTGL",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBvy8hAaDHUseKZTJ6t49V8nuqIaWRfcLI",
    appId: "1:1032197181846:android:8a43ebe34489e7e5ab0db7",
    messagingSenderId: "1032197181846",
    projectId: "livework-be38f",
    storageBucket: "livework-be38f.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBO0c2EbGXclEanVkLRtsnllvZ6yiLV_0c",
    appId: "1:1032197181846:ios:4e96c6258de2c1e3ab0db7",
    messagingSenderId: "1032197181846",
    projectId: "livework-be38f",
    storageBucket: "livework-be38f.firebasestorage.app",
    iosBundleId: "com.company.livework",
  );
}