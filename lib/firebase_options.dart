import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Generated from Firebase Project `rexon-35454`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCM0jl9SOMIcl0RRyv2_jsdnRtnGXi-EBA',
    appId: '1:687145716846:web:afe5360926dcc71ed6ea7f',
    messagingSenderId: '687145716846',
    projectId: 'rexon-35454',
    authDomain: 'rexon-35454.firebaseapp.com',
    storageBucket: 'rexon-35454.firebasestorage.app',
    measurementId: 'G-5FNPRGFZJY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8KnnpAargtfmoUvkGDqjH3AzzIKuZ9lI',
    appId: '1:687145716846:android:f9ebffc67b955f5dd6ea7f',
    messagingSenderId: '687145716846',
    projectId: 'rexon-35454',
    storageBucket: 'rexon-35454.firebasestorage.app',
  );
}
