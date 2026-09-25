import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

// Connection settings for the advanced-mobile-programm-b1110 Firebase project,
// taken from android/app/google-services.json. Android is the only platform
// this activity was built and tested against.
class DefaultFirebaseOptions {
  // Picks the settings for whichever platform the app is running on.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('This app is configured for Android only.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'No Firebase options for $defaultTargetPlatform. '
          'Run `flutterfire configure` to add the platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjiH5A8yiQEu9bzo1yDgGb5ACdHTNo1Do',
    appId: '1:292291489066:android:abb8379d3b3476fbd08253',
    messagingSenderId: '292291489066',
    projectId: 'advanced-mobile-programm-b1110',
    storageBucket: 'advanced-mobile-programm-b1110.firebasestorage.app',
  );
}
