import 'package:youareup/services/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

bool _googleSignInReady = false;

/// Initializes [GoogleSignIn] once at app startup (required for v7+).
Future<void> configureGoogleSignIn() async {
  if (_googleSignInReady || kIsWeb) return;
  final webClientId = DefaultFirebaseOptions.googleWebClientId;
  await GoogleSignIn.instance.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? DefaultFirebaseOptions.ios.iosClientId
        : null,
    serverClientId: defaultTargetPlatform == TargetPlatform.android &&
            webClientId.isNotEmpty
        ? webClientId
        : null,
  );
  _googleSignInReady = true;
}

Future<void> ensureGoogleSignInConfigured() => configureGoogleSignIn();
