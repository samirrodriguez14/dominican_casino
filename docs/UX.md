# UX contract

Goal: a first-time player can enter a name, learn Casino, play vs AI, then invite a friend without dead ends.

## Navigation

- Tab shell (`/landing`): Settings, Games, Profile. **Tabs must have labels**, not only icons (`app_shell.dart`).
- First launch: `/home` name gate, then tutorial if `completedTutorial == false`.
- Settings copy must match reality (today: themes only; tutorial text mentions notifications).

**Contract:** hide `enabled: false` modes. Hide Chat until it works. Do not ship “Coming soon” as a primary control.

Join and deep link must land on `/game/:gameId/:gameMode/:tutorialMode`.

## Tutorial

Casino in-game overlay: `lib/tutorial/tutorial_casino_steps.dart` + `TutorialCasinoFactory`.

**Contract:**

- Highlight keys must match the control (`addButtonKey` / `takeStackButtonKey` currently both point at `playButtonKey`).
- Step numbers unique (duplicate `step: 14` today).
- Opponent-wait steps need skip or auto-advance so the user cannot stick.
- Completing or skipping sets `completedTutorial` only when the script finished or the user confirmed skip.
- How to Play must not always launch Casino tutorial when the user is viewing Tres y Dos.

## Motion and sound

**Motion model (do not patch around this):**

1. Capture card origins from current keys.
2. Mark card ids **in flight**.
3. Commit the new `GameState` so destination slots exist in layout (invisible via `FlightAwareCard` / opacity — never scale-to-0 for flights).
4. Neighbors slide via `SlidingCardLayout` / `AnimatedPositioned`.
5. Overlay flies to the **destination card key**, not the zone center.
6. Clear in-flight → card reveals in place.

Owned by `CardMotionController` + `CardFlightAnimator`. Local and remote updates share `_commitStateWithMotion`.

Sounds: `SoundService` + `assets/sounds/`. Prompts for ElevenLabs: [SOUND_PROMPTS.md](SOUND_PROMPTS.md).

Route transitions: use a consistent Cupertino slide.

## Copy and locale

UI is hardcoded English. Product is Dominican card games.

**Contract:** user-visible strings go through a localization layer (ARB or equivalent) with **es** and **en** before App Store. Action buttons must not show raw enums (`dealSame`, `setReady`).

## Accessibility

**Contract:** every icon-only control has a `Semantics` label (sort, info, chat, status, play). Dynamic Type on chrome; cards may scale within the table. Profile pencil that looks tappable must be tappable.

## Feedback states

Required: loading, empty, error with retry for games list, profile history, and in-match load.

Forbidden: swallow Firebase init (`main.dart` catch), infinite “loading app” if name is null, `e.toString()` as the only error UI, silent `go('/home')` on load failure without a message.

## Fun bar (ship before calling it polished)

1. Deal animation that actually flies cards (reuse unused animator).
2. Capture snap + haptic.
3. Turn banner (“Tu turno” / “Waiting for …”).
4. Round/game end celebration, then scores.
5. Share invite as a first-class “Invite friend” with copy-link success toast.
6. Spanish as default or device locale.
