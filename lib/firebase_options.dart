// Generated from android/app/google-services.json (project: madebymaa-d820e).
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Android & Web (this app does not ship iOS).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:780271006039:web:REPLACE_ME',
    messagingSenderId: '780271006039',
    projectId: 'madebymaa-d820e',
    authDomain: 'madebymaa-d820e.firebaseapp.com',
    storageBucket: 'madebymaa-d820e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAhncBWZv5pYWhp2ncuHx2Oa6-Vs9cRLCA',
    appId: '1:780271006039:android:c7a8b9d0e1f23456789001',
    messagingSenderId: '780271006039',
    projectId: 'madebymaa-d820e',
    storageBucket: 'madebymaa-d820e.firebasestorage.app',
  );
}
