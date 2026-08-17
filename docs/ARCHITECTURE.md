# Architecture contract

## Allowed layering

```
UI (lib/ui/general_game, lib/ui/app_shell)
  → ViewModels (Provider ChangeNotifiers)
    → GameEngine (Casino | TresDos)
      → Handlers (rules, play, state) + EventHandler
        → GameState (mutable, also the Firestore document)
    → AppRepo / GameRepo
      → GameService (FirestoreService)
```

**Contract:** engines must not be constructed in widgets except at the game route factory in `lib/app.dart` until a registry exists. Do not add a third construction site without extracting a factory.

Today there are already two factories (router + `LocalPlayer`). That duplication is a known debt; new games must not add a third switch.

## Persistence

- Collection: `games/{gameId}`
- Writes: full document `set()` in `FirestoreService.updateGame` / `newCreateGame`
- Reads: `streamGame` / `loadGame` / `listenGames` (`playersInfo.$pid.id == pid`)
- Cloud Functions (`functions/src/index.ts`): FCM when `currentTurnPlayerId` changes. **Not** game logic.

**Contract:** do not add a second persistence path (Hive, local JSON, another collection) for match state until engines are I/O-free. Local vs friend games both use Firestore.

## Identity

- `Player` lives in SharedPreferences (`player_id` key) via `AppRepo`.
- Host is **not** in `playersInfo` at create time. Host joins in `GeneralGameViewModel.joinGame()`.
- On-device AI (`LocalPlayer`) is in-memory only. Recreate it in `joinGame` from `isLocalBot` / `botPlayerId` (legacy games: opponent named `Pulilo`). Do not assume a bot from `createNewGame` still exists after a process kill.

**Contract:** any feature that assumes “creator is already a player” is a bug.

## Live vs dead UI

| Live (keep) | Dead (do not extend) |
|-------------|----------------------|
| `lib/ui/general_game/` | `lib/ui/legacy_game/` except `popups/players_deck_content.dart` |
| `lib/view_models/games/general_game_view_model.dart` | `lib/ui/legacy_game/game_view_model.dart` |
| `lib/ui/cards/card_deck.dart` | `lib/ui/cards/gen_card_deck.dart` |
| `lib/ui/app_shell/` | `lib/ui/app_shell/profile/challenge_players.dart` (stub) |

**Contract:** new screens attach to `go_router` in `lib/app.dart` and the tab shell. Do not revive `GameScreen`.

## Routing

| Path | Notes |
|------|--------|
| `/`, `/home` | First-run name + start |
| `/landing` | Tab shell (settings / games / profile) |
| `/instructions`, `/tutorial` | How-to and slide tutorial |
| `/join/:gameId/:gameMode` | Redirects to `/game/.../false` |
| `/game/:gameId/:gameMode/:tutorialMode` | Live match |

**Contract:** every navigation to a match must include all three game-route segments. Deep links must include `gameMode`.

Known bugs (do not copy): join-by-ID uses `/game/$id/$mode` (missing tutorial flag); URI handler uses `/join/$gameId` (missing mode).

## Providers (`lib/main.dart`)

Registered: `FirestoreService`, `GameRepo`, `AppRepo`, `ProfileViewModel`, `GamesViewModel`, `HomeViewModel`, `AppThemeViewModel`.

**Contract:** `GeneralGameViewModel` is per-route, not global. `GameRepo` holds one active stream; switching matches must cancel/listen for the new `gid`.

Do not construct a second `FirestoreService()` in the router (current code does). Inject `context.read<FirestoreService>()`.

## Performance contracts

- `GameState` is a god object streamed on every snapshot. Do not add large blobs (chat history, replay logs) onto the same document.
- `cardMoveEvents` is the play/capture/deal animation bus. End-of-round leftover collects use `settlementEvents` (separate phase). Append, do not rewrite history without a client-side id filter (`lastPlayedIds`).
- `getInGameAction` must stay a **pure read**. Writing `readyToStart` from a getter (current Casino/Tres y Dos engines) is forbidden in new code; move that to an explicit join/ready method.
- Full-document `set` is last-writer-wins. New concurrent writes (join vs play) must use transactions or `update` with field paths before shipping ranked play.

## Adding money or more games

- More games: follow [GAME_ENGINE.md](GAME_ENGINE.md). Do not grow `PlayAction` for unrelated mechanics without a per-game action type.
- Coins / store: forbidden on this architecture. See [SECURITY.md](SECURITY.md). Requires Auth + server-authoritative apply + a ledger collection engines cannot `set()`.
