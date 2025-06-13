// File ini dibuat oleh FlutterFire CLI.
// Ini berisi opsi konfigurasi untuk Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opsi konfigurasi default untuk menggunakan Firebase API.
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
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform Windows - '
          'anda dapat membuat konfigurasi ini dengan mengikuti dokumentasi FirebaseCLI: https://firebase.google.com/docs/flutter/setup',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions belum dikonfigurasi untuk platform Linux - '
          'anda dapat membuat konfigurasi ini dengan mengikuti dokumentasi FirebaseCLI: https://firebase.google.com/docs/flutter/setup',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions tidak tersedia untuk platform ini.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDW5et8-Cn_mxvLa2BDpTVKB8g_UMYJz5A',
    appId: '1:990106378790:web:52dab7f99ae7ad642c7ce7',
    messagingSenderId: '990106378790',
    projectId: 'daily-checklist-student',
    authDomain: 'daily-checklist-student.firebaseapp.com',
    storageBucket: 'daily-checklist-student.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDW5et8-Cn_mxvLa2BDpTVKB8g_UMYJz5A',
    appId: '1:990106378790:android:52dab7f99ae7ad642c7ce7',
    messagingSenderId: '990106378790',
    projectId: 'daily-checklist-student',
    storageBucket: 'daily-checklist-student.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDW5et8-Cn_mxvLa2BDpTVKB8g_UMYJz5A',
    appId: '1:990106378790:ios:52dab7f99ae7ad642c7ce7',
    messagingSenderId: '990106378790',
    projectId: 'daily-checklist-student',
    storageBucket: 'daily-checklist-student.firebasestorage.app',
    iosBundleId: 'com.daily-checklist-student',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDW5et8-Cn_mxvLa2BDpTVKB8g_UMYJz5A',
    appId: '1:990106378790:macos:52dab7f99ae7ad642c7ce7',
    messagingSenderId: '990106378790',
    projectId: 'daily-checklist-student',
    storageBucket: 'daily-checklist-student.firebasestorage.app',
    iosBundleId: 'com.daily-checklist-student.RunnerTests',
  );
}
