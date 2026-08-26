# Contracts

These files are the source of truth for how this app is allowed to change.
If a PR contradicts a contract, update the contract in the same PR or reject the change.

| File | Use when |
|------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Layers, live vs dead UI, persistence |
| [GAME_ENGINE.md](GAME_ENGINE.md) | Adding or changing a card game |
| [DATA_MODEL.md](DATA_MODEL.md) | Firestore `games` document shape |
| [SECURITY.md](SECURITY.md) | Auth, rules, cheating, coins |
| [IOS_RELEASE.md](IOS_RELEASE.md) | App Store packaging |
| [ANDROID_RELEASE.md](ANDROID_RELEASE.md) | Play Store packaging and emulator setup |
| [UX.md](UX.md) | Navigation, tutorial, sound, animation |
| [DOMINION_JOURNEY.md](DOMINION_JOURNEY.md) | Journey progression, worlds, characters, canon |

**Current product facts:**

- Flutter + Firestore. Identity is **Firebase Anonymous Auth** (`request.auth.uid`).
- FCM tokens live under `users/{uid}` — never on game docs.
- Two playable engines via `GameRegistry`. Engines are I/O-free; callers persist.
- Robaito is catalog-only and hidden from the carousel.
- Deploy: `firebase deploy --only firestore:rules,functions,hosting`
- Enable **Anonymous** sign-in in Firebase Console → Authentication.
- Bundle / application id is `com.sr2.dominicanCasino` on iOS and Android — keep Firebase configs (`GoogleService-Info.plist`, `google-services.json`) in sync when rotating apps.

Updated 2026-08-25.
