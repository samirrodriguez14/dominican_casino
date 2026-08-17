# Data model contract

## Collections

| Path | Writer today | Purpose |
|------|----------------|---------|
| `games/{gid}` | Any client | Entire match |
| (none) | — | Users, wallets, purchases |

There is no `users` collection. Display name and FCM token are copied into `playersInfo` on join.

## `games/{gid}` fields

Must stay in sync with `GameState.toJson` / `fromMap` (`lib/models/game_state.dart`).

| Field | Meaning |
|-------|---------|
| `id` | 8-char UUID substring |
| `gameMode` | `casino` \| `tresydos` \| `robaito` |
| `gameStatus` | `waitingForPlayers` \| `readyToStart` \| `inProgress` \| `gameOver` \| `error` |
| `controllerId` | Host player id (local UUID) |
| `started` | Deal/start has run |
| `currentTurnPlayerId` | FCM trigger field |
| `deck` | Remaining draw pile (**secret in honest UI, public in Firestore**) |
| `playingArea` | Table cards |
| `playingAreaStacks` | Casino builds |
| `hands` | All players’ hands (**public**) |
| `playersDeck` | Captured piles |
| `scores` | Match points by pid |
| `extraPoints` / `extraPointsHolderId` | Casino virao |
| `lastTookCardId` | Last capture |
| `playersInfo` | `{ id, name, token }` per pid |
| `isLocalBot` | True when the opponent is the on-device AI (Puli) |
| `botPlayerId` | Pid of that AI seat; used to recreate `LocalPlayer` after a cold start |
| `winnerId` | Empty string until over |
| `round` | `{ id, roundStatus, roundScores }` |
| `cardMoveEvents` | Play / capture / deal animation events |
| `settlementEvents` | End-of-round leftover collect only (separate motion phase) |

**Contract:** adding a field requires `toJson` + `fromMap` in the same PR. `updateGame` is a full replace; omitted fields are deleted.

## IDs

- Game id and player id: `_uuid.v4().substring(0, 8)` (~32 bits).
- **Contract:** new ids must be full UUIDs or Firestore auto-ids before public multiplayer. Short ids are enumerable.

## Player (device)

`Player`: `id`, `name` (UI max 10 chars), `token`, `completedTutorial`. Stored only in SharedPreferences until join copies it onto the game.

## Queries

`listenGames(pid)`: `where('playersInfo.$pid.id', isEqualTo: pid)`.

**Contract:** nested maps keyed by pid make indexes and rules painful. New list queries should use a `playerIds: string[]` array field and `array-contains`.

## Events

`CardMoveEvent` is the cross-client animation protocol (`lib/game_control/interfaces/card_event.dart` + `Zone`).

**Contract:** every successful play that moves cards must emit events. Clients hide cards listed in `lastPlayedIds`. Do not clear `lastPlayedIds` across games without resetting the repo.

## Forbidden on this document

- Wallet / coin balances
- IAP transaction ids
- Chat transcripts (use a subcollection later)
- Opponent-hidden hands (requires server-side state or private subdocs)

Changing JSON without a migration plan is a breaking change for in-flight matches.
