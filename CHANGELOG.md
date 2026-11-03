# Changelog

Release versions live in `pubspec.yaml` as `name+build` (e.g. `0.1.1+8`).
Bump **name** for store-facing releases; bump **build** on every upload to App Store Connect / Play Console.

Copy the **Store “What’s New”** blurb into the review submission for that version.

## 0.1.1+8 — 2026-11-03

### Store “What’s New”

- Smoother Quick Match: cancelled or timed-out searches no longer leave idle Sweep games for others.
- Notification badge clears when you open the app (no red-dot flash).
- Polished home carousel and Sweep tutorial flow.
- Fresh App Store screenshots and brand creatives for Barajando.

### Changes

- Matchmaking: abandon stale waiting tickets on launch; cancel/timeout no longer overwrites a matched ticket (fixes orphaned Sweep lobbies).
- Notifications: clear badge and delivered notifications on `willEnterForeground` / launch; disable foreground FCM badge presentation; skip duplicate local notifications when FCM already carries a notification payload; preserve `currentGames` on resume so the home peek badge does not flicker.
- Home: fan carousel far-side peek animates during restack; Games Quick Match opens the quick-play dialog.
- Tutorials: Sweep-only path (no game-mode picker).
- Branding: Barajando B mark; store screenshot capture + framed creatives (`store_screenshots/`, `tool/compose_store_*.py`).

## 0.1.0 — baseline

First review / distribution baseline for Barajando (formerly dominican_casino). Build numbers through `+7` shipped under this name version.
