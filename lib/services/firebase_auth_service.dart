import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthSession {
  String? uid;
  String? token;
  String? imageUrl;
  AuthSession({required this.token, required this.uid, required this.imageUrl});

  factory AuthSession.fromDto(Map<String, dynamic> authSessionDto) {
    return AuthSession(
      imageUrl: authSessionDto['imageUrl'],
      token: authSessionDto['token'],
      uid: authSessionDto['uid'],
    );
  }
}

class FirebaseAuthService {
  final fb.FirebaseAuth _auth;
  FirebaseAuthService({required this._auth});

  Future<AuthSession?> getCurrentSession({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    try {
      final accessToken = await user.getIdToken();
      if (accessToken == null) {
        return null;
      }
      return AuthSession(
        token: accessToken,
        uid: user.uid,
        imageUrl: user.photoURL,
      );
    } catch (e) {
      developer.log("Error getting session: $e");

      return null;
    }
  }

  Future<AuthSession?> login() async {
    try {
      fb.UserCredential cred;
      if (kIsWeb) {
        developer.log("google sign in web Start");
        await GoogleSignIn.instance.initialize(
          clientId:
              "932020449632-la1rnifajdj2jfdo8mrgtbskdpe0iljp.apps.googleusercontent.com",
        );

        final provider = fb.GoogleAuthProvider();
        cred = await fb.FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        developer.log("google sign in Mobile Start");

        await GoogleSignIn.instance.initialize();
        final google = GoogleSignIn.instance;
        final googleAccount = await google.authenticate();
        developer.log("gsiMobile $googleAccount");

        final oAuthCred = fb.GoogleAuthProvider.credential(
          idToken: googleAccount.authentication.idToken,
        );
        cred = await _auth.signInWithCredential(oAuthCred);
      }
      final user = cred.user;
      final token = await user?.getIdToken();
      return AuthSession(
        token: token,
        uid: user?.uid,
        imageUrl: user?.photoURL,
      );
    } catch (e) {
      developer.log("error logging in: $e");
    }
    return null;
  }

  Future<void> logout() async{
    await _auth.signOut();
  }
}
