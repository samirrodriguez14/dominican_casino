# iOS / App Store contract

Version in `pubspec.yaml`: `0.1.0+1`. Bundle id in Firebase/Xcode: `com.example.dominicanCasino` (placeholder).

## Blockers before first upload

| Item | Contract |
|------|----------|
| Bundle id | Own `com.<org>.<app>` in Xcode, Firebase, AASA, entitlements |
| Push | `aps-environment` = `production` for TestFlight/App Store (`ios/Runner/Runner.entitlements` is `development`) |
| Marketing icon | 1024×1024, **no alpha**. `flutter_launcher_icons` source is `logo_icon_wooden_transparent.png` — replace |
| Launch screen | Branded; current storyboard is default Flutter white + LaunchImage |
| Privacy policy | URL in App Store Connect and in Settings |
| App Privacy nutrition | Firestore + FCM: Device ID, Product Interaction, Identifiers |
| Privacy Manifest | `PrivacyInfo.xcprivacy` (UserDefaults / `shared_preferences`) |
| Encryption | Set `ITSAppUsesNonExemptEncryption` = false if HTTPS-only, or answer the questionnaire |
| Account deletion | In-app delete of local player + server `playersInfo` / tokens, or no server identity |
| Unused background mode | Remove `fetch` unless implemented; keep `remote-notification` only if push ships |
| Age | Casino-style: typically 17+; state no real-money gambling |

## Should fix (review or crash risk)

- Register `assets/config/` in `pubspec.yaml` so `games.json` / `instructions.json` load.
- Notification permission: in-app rationale, not on first `loadApp`.
- Portrait: Flutter locks portrait; Info.plist still lists landscape. Align them.
- Universal Links AASA must use the shipping bundle id.
- No custom URL scheme (`CFBundleURLTypes`); fine if Associated Domains work.

## Not required yet

- StoreKit / IAP / Restore — only when a store exists ([SECURITY.md](SECURITY.md)).
- App Tracking Transparency — only if you use IDFA or cross-app tracking.
- Camera / photo usage strings — do not add keys for unused APIs.

## Android / web

No `google-services.json` in repo. Do not claim Android in the store listing until configured. Web hosting is used for invite links (`dominican-casino.web.app`).

## TestFlight smoke list

- Cold start, name entry, tutorial complete / cannot get stuck on AI steps
- Create local Casino + Tres y Dos through a round
- Friend invite link opens the **correct** mode and join succeeds
- Push on turn (production entitlement)
- Kill app mid-match; reopen and resume
- Delete / resign; history on Profile
- VoiceOver on tab bar and table actions (see [UX.md](UX.md))
