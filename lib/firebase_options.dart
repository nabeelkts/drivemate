// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyCI8-HLaRDuj-5GcdI_xoYJJkZSusZBIAU',
    appId: '1:694652953963:web:0414da3ddb51a658e6582e',
    messagingSenderId: '694652953963',
    projectId: 'smds-c1713',
    authDomain: 'smds-c1713.firebaseapp.com',
    storageBucket: 'smds-c1713.appspot.com',
    measurementId: 'G-3SNYZSN6RQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXiXhkXKfn3PnhapAYJAWemfjX8IUYG9g',
    appId: '1:694652953963:android:2ffce743c90e1c15e6582e',
    messagingSenderId: '694652953963',
    projectId: 'smds-c1713',
    storageBucket: 'smds-c1713.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC8-L5lNulEs3vwYa6N_FwToqxmwe7CU-M',
    appId: '1:694652953963:ios:aa210b0a54fa35bce6582e',
    messagingSenderId: '694652953963',
    projectId: 'smds-c1713',
    storageBucket: 'smds-c1713.appspot.com',
    iosBundleId: 'com.example.mds',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC8-L5lNulEs3vwYa6N_FwToqxmwe7CU-M',
    appId: '1:694652953963:ios:07e2c4ffde3808dae6582e',
    messagingSenderId: '694652953963',
    projectId: 'smds-c1713',
    storageBucket: 'smds-c1713.appspot.com',
    iosBundleId: 'com.example.mds.RunnerTests',
  );
}
