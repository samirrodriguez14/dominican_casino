import 'package:dominican_casino/services/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool _googleSignInReady = false;

/// Initializes [GoogleSignIn] once at app startup (required for v7+).
Future<void> configureGoogleSignIn() async {
  if (_googleSignInReady || kIsWeb) return;
  await GoogleSignIn.instance.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
    serverClientId: defaultTargetPlatform == TargetPlatform.android
        ? DefaultFirebaseOptions.googleWebClientId
        : null,
  );
  _googleSignInReady = true;
}

Future<void> ensureGoogleSignInConfigured() => configureGoogleSignIn();
