# App Store screenshots & creatives (Barajando)

Upload these into App Store Connect. Skip Apple Watch and App Previews.

## Upload checklist

### Header
- [ ] [`creative/header-3840x2560.png`](creative/header-3840x2560.png) — product page header

### Search Results
- [ ] [`creative/search-3840x2560.png`](creative/search-3840x2560.png) — search listing asset

### iPhone with Dynamic Island (medium) — portrait screenshots
Upload in this order (1 → 6):

1. [`framed/iphone/01-games-1206x2622.png`](framed/iphone/01-games-1206x2622.png)
2. [`framed/iphone/02-sweep-1206x2622.png`](framed/iphone/02-sweep-1206x2622.png)
3. [`framed/iphone/03-tresydos-1206x2622.png`](framed/iphone/03-tresydos-1206x2622.png)
4. [`framed/iphone/04-rummy-1206x2622.png`](framed/iphone/04-rummy-1206x2622.png)
5. [`framed/iphone/05-journey-1206x2622.png`](framed/iphone/05-journey-1206x2622.png)
6. [`framed/iphone/06-profile-1206x2622.png`](framed/iphone/06-profile-1206x2622.png)

Size: **1206 × 2622**

### iPad 13" display — portrait screenshots
Same storyboard order:

1. [`framed/ipad/01-games-2064x2752.png`](framed/ipad/01-games-2064x2752.png)
2. [`framed/ipad/02-sweep-2064x2752.png`](framed/ipad/02-sweep-2064x2752.png)
3. [`framed/ipad/03-tresydos-2064x2752.png`](framed/ipad/03-tresydos-2064x2752.png)
4. [`framed/ipad/04-rummy-2064x2752.png`](framed/ipad/04-rummy-2064x2752.png)
5. [`framed/ipad/05-journey-2064x2752.png`](framed/ipad/05-journey-2064x2752.png)
6. [`framed/ipad/06-profile-2064x2752.png`](framed/ipad/06-profile-2064x2752.png)

Size: **2064 × 2752**

## Regenerate

Captions live in [`manifest.json`](manifest.json).

```bash
# 1) Boot a simulator, then capture with the store-shot entrypoint
#    (do NOT use --dart-define=STORE_SCREENSHOTS — it sticks in Generated.xcconfig):
flutter run -d <UDID> -t lib/main_store_shots.dart 2>&1 | tee /tmp/barajando-shots.log

# 2) In another terminal, watch markers and write raw PNGs:
tool/capture_store_screenshots.sh <UDID> store_screenshots/raw/iphone /tmp/barajando-shots.log
# or …/raw/ipad for the 13" iPad

# 3) Compose branded frames:
tool/.venv/bin/python tool/compose_store_screenshots.py

# 4) Header + Search creatives:
tool/.venv/bin/python tool/compose_store_creatives.py
```

Pillow venv: `python3 -m venv tool/.venv && tool/.venv/bin/pip install Pillow`

## Notes

- Raw captures are real Simulator UI (`raw/`). Framed exports add sage/gold caption bands.
- Store-shot mode skips notification permission prompts and first-run tutorial popups.
- Normal `flutter run` / Xcode builds never run the tour (flag stays off).
- English captions only; swap strings in `manifest.json` for a Spanish set later.
