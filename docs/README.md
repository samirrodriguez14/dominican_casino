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
| [UX.md](UX.md) | Navigation, tutorial, sound, animation |

**Current product facts (not marketing):**

- Flutter + Firestore. Identity is a local 8-character UUID, not Firebase Auth.
- Two playable engines: Casino and Tres y Dos. Robaito is catalog-only (`enabled: false`).
- Clients write the full game document. Cloud Functions only send FCM on turn change.
- There is no wallet, IAP, or betting. Do not add those on the current write path.

Reviewed against the codebase on 2026-08-16.
