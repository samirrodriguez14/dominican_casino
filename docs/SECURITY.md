# Security contract

## Current trust model (honest clients only)

Anyone who can reach project `dominican-casino` can read and write `games/{id}` unless Console rules are stricter than this repo. **This repo has no `firestore.rules` and `firebase.json` does not deploy rules.**

There is **no Firebase Auth**. Player ids are local and spoofable.

Treat ranked integrity, coins, and the App Store as **blocked** until the gates below are done.

## Must not ship with coins / betting / paid influence

Guideline 3.1.1: virtual currency and IAP must not be grantable by a trusted client.

**Contract:**

- Clients must not `set()` balances, pots, or “coins spent to redraw.”
- Match outcome (`scores`, `winnerId`, hands, deck) must be applied by a Cloud Function / callable that validates the move.
- IAP uses StoreKit + server receipt (App Store Server API). Restore Purchases is required.
- Bind ledger rows to `request.auth.uid`, not the 8-char SharedPreferences id.

Adding a `coins` field to `GameState` is a security regression, not a feature.

## Required before public multiplayer (even free)

1. **`firestore.rules` in repo** and a `firebase.json` `firestore` block. Default deny. Authenticated players may create a game they host; they may update only through Functions, or only allowlisted fields (e.g. `playersInfo.{uid}` on join) if you keep client writes temporarily.
2. **Firebase Auth** (anonymous is acceptable for v1; upgrade to Sign in with Apple for App Store if you keep accounts).
3. **App Check** on Firestore and Functions.
4. **Longer game ids**; do not put FCM tokens on world-readable game docs (store tokens on `users/{uid}`).
5. Stop logging FCM tokens (`FirestoreService.getDeviceToken`, `AppRepo.getDeviceToken`).
6. Fix `saveToken` (`playersInfo.$pid. ` has a trailing space / empty field).

## Cheating that works today

- Peek `hands` and `deck` via REST.
- Rewrite `winnerId` / `scores` / `currentTurnPlayerId`.
- Delete any game (`deleteGame`).
- Join any short id; deep links are capability URLs without auth.
- Flip turn to spam FCM (`onTurnChange` has no auth).

Client `validateAction` is UX, not security.

## Privacy

- FCM tokens in `playersInfo` are identifiers. Disclose in App Privacy if you ship notifications.
- Push permission is requested during `loadApp` with no explanation. Guideline 5.1.1: explain first.
- Account deletion: if game docs contain player data, provide in-app deletion (5.1.1(v)) or stop storing identity on the server.

## Deep links

Associated domain: `applinks:dominican-casino.web.app`.

**Contract:** allowlist `gameId` (uuid format). Always pass `gameMode`. Do not concatenate unsanitized ids into extra path segments. Keep invite pages same-origin (current `public/index.html` pattern).

## Naming / gambling

Product name includes “Casino.” Simulated play without cash is allowed (5.3) but expect 17+ rating and a clear **no real money** statement. Real-money betting is out of scope and illegal to add via IAP tricks.

## Functions contract

`onTurnChange` may only send push. It must not become the wallet. New game-apply functions must:

- Require Auth
- Load the document in a transaction
- Verify it is the caller’s turn
- Apply one validated action
- Write the new state
- Never accept a client-supplied full `GameState`
