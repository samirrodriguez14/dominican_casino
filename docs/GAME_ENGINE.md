# Game engine contract

## What a “game” is

A playable mode is all of:

1. Catalog entry in `assets/config/games.json` with `enabled: true`
2. `GameMode` enum case + `gameModeFrom` / `gameModeTo` in `lib/models/game_state.dart`
3. `GameEngine` subclass under `lib/game_control/game_engine/<mode>/`
4. Router switch in `lib/app.dart`
5. Create switch in `lib/ui/app_shell/games/game_mode_card.dart`
6. Playing-area widget in `GeneralGameScreen._selectPlayingArea`
7. AI branch in `lib/local_player/` if `aiSupported: true`
8. Deal counts in `performInGameAction`

If any item is missing, the mode must stay `enabled: false` and must not appear as a Play target.

## `GameEngine` surface (do not change lightly)

```
getAvailableActions(state, selection) → List<PlayAction>
validateAction(state, selection, action) → ValidateResult
performPlayAction(state, selection, action) → Future<GameState>
getInGameAction(state, pid) → InGameAction
performInGameAction(state, action, pid) → Future<GameState>
```

**Contract:**

- Validate before mutate. Invalid moves must not call `gameService.updateGame`.
- Persist only after mutation + `cardMoveEvents` are set.
- `getInGameAction` is a query. No Firestore writes.
- Turn advance is game-specific (Casino: after a hand-card play; Tres y Dos: when hand size returns to 5). Document the rule in the mode’s state handler.

## Shared vs per-game

| Shared (change carefully) | Per-game |
|---------------------------|----------|
| `GameState` document | Rules / play / state handlers |
| `InGameAction` enum | Deal counts (Casino 4+4, Tres y Dos 5+1) |
| `EventHandler` + `Zone` | Playing-area UI |
| `GameActionHandler` deal/shuffle | Win condition and scoring |
| `PlayAction` types (Casino-shaped) | Which actions are legal |

**Contract:** do not put Casino-only checks in `GameActionHandler` or `LocalPlayer` for “all modes”. `shouldDealSameRound` is Casino-only. Tres y Dos uses `shuffle`, not `dealSame`.

Unknown `gameMode` string:

- `gameModeFrom` currently defaults to **robaito**
- Router currently defaults to **Casino engine**

**Contract:** unknown modes must fail closed (error status / no engine), not silently pick a game.

## Catalog vs engines

| id | Engine | Catalog max players | Engine max |
|----|--------|---------------------|------------|
| casino | yes | 2 | 2 |
| tresydos | yes | 4 | 2 (hard-coded) |
| rummy | yes | 4 | 4 |
| robaito | no | 4 | — |

**Contract:** `games.json` `players.max` must match the engine. Tres y Dos JSON says 4; code is 2. Fix one side before advertising 4-player.

`pubspec.yaml` must list `assets/config/` (today only `assets/images/` is listed). Catalog loads `config/games.json`.

## Adding a new mode (checklist)

1. Add JSON object; keep `enabled: false` until the engine ships.
2. Add enum + serialization. Never reuse the `default: robaito` branch.
3. Implement handlers. Prefer composition over copying Casino then deleting cases.
4. Register in **one** factory used by router and `LocalPlayer`.
5. Add playing area; return a placeholder “coming soon” — never `null` on a live route.
6. If actions are not capture/build, add types in `action.dart` **and** `EventHandler` in the same PR.
7. Tutorial is Casino-only. New modes need their own factory or must not claim tutorial support.
8. Hide the carousel tile when `enabled: false`. Do not ship no-op Play buttons.

## Scoring vs currency

`scores`, `extraPoints`, and `winnerId` are **match points**, not coins.

Casino: first to 21 (plus virao extras). Tres y Dos: 3 round points; a round is 3-of-a-kind + 2-of-a-kind.

**Contract:** do not store wallet balances on `GameState`. See [SECURITY.md](SECURITY.md).
