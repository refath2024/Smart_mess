// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyD1MJFUDf_uQ5nfPF_ZYNJH2AcM63hxDRM',
    appId: '1:477255080513:web:c8df24030ac7ce67da04c0',
    messagingSenderId: '477255080513',
    projectId: 'smart-mess-dfe03',
    authDomain: 'smart-mess-dfe03.firebaseapp.com',
    storageBucket: 'smart-mess-dfe03.firebasestorage.app',
    measurementId: 'G-DB479HY0GX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-INObGkM5Wwy4lzIeMd6gDktPEmGu9JE',
    appId: '1:477255080513:android:7bb3fc6aadd1ae8fda04c0',
    messagingSenderId: '477255080513',
    projectId: 'smart-mess-dfe03',
    storageBucket: 'smart-mess-dfe03.firebasestorage.app',
  );
}
