# ElevenLabs sound prompts

Use **Sound Effects** (not Text to Speech). Export WAV, then replace files in `assets/sounds/`.

Style: Dominican kitchen-table casino — green felt, walnut wood, paper cards, close and dry. Not Vegas neon, not cartoon, not a synth whoosh.

**Shared style line** (paste at the start of each prompt):

```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.
```

**Avoid in every clip:** music, voices, crowd, chips raining, slot machines, lasers, whoosh, hall reverb, plastic cards, video-game UI beeps.

| Clip | Duration | Prompt influence | Loop |
|---|---|---|---|
| Shuffle | 1.0–1.2s | 75–85% | Off |
| Deal | 0.25s | 80–90% | Off |
| Capture | 0.30s | 80–90% | Off |
| Win | ~0.8s | 75–85% | Off |
| Illegal | 0.15s | 80–90% | Off |
| Your turn | 0.3s | 80–90% | Off |

---

## 1. `shuffle.wav` — deck shuffle

Played once when the dealer shuffles (`GameSound.shuffle`).

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

A short riffle shuffle of a 52-card paper deck: two halves spring together with a quick flutter of card edges, then a soft square-up tap on felt. One compact gesture, not a long cascade. Natural paper texture, light wooden table resonance underneath. 1.1 seconds, ends cleanly with silence.
```

**Tighter fallback:**
```
Quick close-up riffle shuffle of paper playing cards, then a single soft tap to square the deck on felt. Dry, intimate, 0.9 seconds. No chips, no crowd, no whoosh.
```

---

## 2. `deal.wav` — card dealt from the shoe

One clip covers dealing from the shoe and playing a card onto the table (trail/build). Make it a **single card**, not a whole hand.

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

A single playing card dealt onto felt: brief slide off the deck, then a light paper snap as it lands. Thin, quick, dry. One card only. 0.22 seconds.
```

**Warmer fallback** (better for a card laid onto the table):
```
One paper playing card placed onto green felt with a soft sliding tap and a tiny wooden table tick. Close-mic, dry, 0.25 seconds. No whoosh, no multiple cards.
```

**Negative / avoid:** whoosh, laser, digital beep, long echo, multiple cards

---

## 3. `capture.wav` — take / capture cards

Reward snap when any Take action succeeds. Fuller than deal: scooping cards into a pile.

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

Satisfying card capture: two or three paper playing cards scooped together into a small pile on felt, crisp layered paper slap with a short walnut-table knock. Warm, tactile, rewarding but not loud. 0.30 seconds, ends cleanly.
```

**Sweep fallback:**
```
A small stack of paper cards gathered off green felt in one scoop, overlapping paper slaps then a soft pile settle on wood. Close, dry, 0.35 seconds. No coins, no crowd cheer.
```

---

## 4. `win.wav` — round or game win

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

Subtle casino win stinger: soft bright chip clink followed by a gentle muted fanfare-like chord, warm and classy, not cartoon, no voice, about 0.8 seconds, ends cleanly
```

---

## 5. `illegal.wav` — invalid move

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

Soft error cue for a card game UI: low muted thud with a short dry wood knock, polite not harsh, no buzzer, no alarm, 0.15 seconds
```

---

## 6. `your_turn.wav` — it is your turn

**Prompt:**
```
Foley for a premium mobile Dominican card game. Intimate close-mic, dry, no reverb. Real paper playing cards on green casino felt over a walnut wooden table. Warm, tactile, classy home-casino. No music, no voices, no crowd, no synthesizers.

Gentle attention chime for a turn notification: two soft high woodblock or chip taps ascending slightly, friendly and quiet, no melody loop, 0.3 seconds
```

---

## Generation tips

- Generate 3–4 variations each; pick the quietest, driest, most “on the table” take.
- Treat shuffle, deal, and capture as one family: same room, same materials. Deal is lightest (one card). Capture is 2–3 cards and slightly heavier. Shuffle is a short flutter then a tap.
- If shuffle sounds like a different room (more echo, more bass, more “Hollywood”), regenerate until it matches deal.
- Normalize so deal and capture peak at about the same loudness; shuffle a touch quieter so a 1s clip does not blast; win slightly louder; illegal quieter.
- Prefer mono or stereo centered; avoid heavy reverb (reads as distant, not on-table).
