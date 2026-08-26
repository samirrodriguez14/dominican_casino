# Android / Play Store contract

Version in `pubspec.yaml`: `0.1.0+1`. Application id / package: `com.sr2.dominicanCasino` (matches iOS bundle id).

Firebase Android app id: `1:932020449632:android:6541fabbce84c931c9ee05`. Config file: [`android/app/google-services.json`](../android/app/google-services.json). Dart options: [`lib/services/firebase_options.dart`](../lib/services/firebase_options.dart).

## Blockers before first Play upload

| Item | Contract |
|------|----------|
| Application id | Keep `com.sr2.dominicanCasino` in Gradle, Firebase, and Digital Asset Links |
| `google-services.json` | Present under `android/app/`; Google Services Gradle plugin applied |
| Signing | Replace debug signing with a release keystore before Play; upload SHA-1/SHA-256 to Firebase |
| Debug SHA | Local debug keystore fingerprints must stay registered in Firebase for Google Sign-In on emulators/dev builds |
| Push | `POST_NOTIFICATIONS` in the main manifest; request via in-app rationale (`AppRepo.enableNotifications`) |
| Notification icon | Use `@mipmap/launcher_icon` (not `ic_launcher`) |
| Privacy policy | URL in Play Console and in Settings |
| Data safety | Firestore + FCM: Device ID, Product Interaction, Identifiers |
| Account deletion | Same in-app path as iOS |
| Age | Casino-style: typically 17+; state no real-money gambling |

## Deep links

| Link type | Status |
|-----------|--------|
| Custom scheme `dominicancasino://` | Declared in `AndroidManifest.xml` |
| HTTPS App Links (`dominican-casino.web.app` `/join/*`, `/game/*`) | Manifest `autoVerify=true` + [`public/.well-known/assetlinks.json`](../public/.well-known/assetlinks.json) |

When rotating the release signing cert, update `assetlinks.json` SHA-256 and redeploy hosting.

## Should fix before claiming Android in store listing

- Create a release keystore; wire `signingConfigs.release` in `android/app/build.gradle.kts`
- Register release SHA-1/SHA-256 in Firebase Console → Android app
- Verify App Links with `adb shell pm get-app-links com.sr2.dominicanCasino`
- Confirm Google Sign-In on a physical device (SHA fingerprints + OAuth client)

## Emulator / local run

Use **JDK 17** (Android Studio’s bundled JDK 25 is incompatible with the current Gradle wrapper):

```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
flutter config --jdk-dir "$JAVA_HOME"
flutter config --android-sdk "$ANDROID_HOME"
flutter emulators --launch Pixel_7_API_35
# or: emulator -avd Pixel_7_API_35 -no-snapshot-load
flutter run -d emulator-5554
```

Debug SHA fingerprints (register in Firebase for Google Sign-In):

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```

## Smoke list

- Cold start, anonymous auth, name entry
- Create local Casino + Tres y Dos through a round
- Google account linking (Apple must not appear)
- Notification permission prompt + FCM token under `users/{uid}`
- Custom-scheme invite opens the correct mode
- HTTPS invite opens the app after `assetlinks.json` is deployed
- Kill app mid-match; reopen and resume
- Portrait lock and audio playback

## Not required yet

- Play Billing / IAP — only when a store exists ([SECURITY.md](SECURITY.md))
- App Tracking / Advertising ID — only if used
- Camera / photo permissions — do not add for unused APIs
