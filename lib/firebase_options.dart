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
        return windows;
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
    apiKey: 'AIzaSyDkW4bafu2WrHbctmoiM3tjNRgdQH6jAb0',
    appId: '1:380672168202:web:dff8f63bc7b4d2a7fd6af3',
    messagingSenderId: '380672168202',
    projectId: 'nutrimotion-e4184',
    authDomain: 'nutrimotion-e4184.firebaseapp.com',
    storageBucket: 'nutrimotion-e4184.firebasestorage.app',
    measurementId: 'G-XRG34C9M54',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIeXGy29UhFsi_fUkq0Y_sncLUdPo7SaM',
    appId: '1:380672168202:android:3ef8aa58f4d306dffd6af3',
    messagingSenderId: '380672168202',
    projectId: 'nutrimotion-e4184',
    storageBucket: 'nutrimotion-e4184.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCWpx8Kb0B7NAf222swIDuPj8ln9H70s7E',
    appId: '1:380672168202:ios:e72021d7675084a2fd6af3',
    messagingSenderId: '380672168202',
    projectId: 'nutrimotion-e4184',
    storageBucket: 'nutrimotion-e4184.firebasestorage.app',
    iosBundleId: 'com.example.nutrimotion',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCWpx8Kb0B7NAf222swIDuPj8ln9H70s7E',
    appId: '1:380672168202:ios:e72021d7675084a2fd6af3',
    messagingSenderId: '380672168202',
    projectId: 'nutrimotion-e4184',
    storageBucket: 'nutrimotion-e4184.firebasestorage.app',
    iosBundleId: 'com.example.nutrimotion',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDkW4bafu2WrHbctmoiM3tjNRgdQH6jAb0',
    appId: '1:380672168202:web:1f3cea9d36ff203ffd6af3',
    messagingSenderId: '380672168202',
    projectId: 'nutrimotion-e4184',
    authDomain: 'nutrimotion-e4184.firebaseapp.com',
    storageBucket: 'nutrimotion-e4184.firebasestorage.app',
    measurementId: 'G-RMHHQS15KN',
  );
}
