# Dominican Casino — Dominion Journey

> **Status:** Core canon / progression specification
> **Purpose:** Keep gameplay progression, world themes, characters, unlocks, and future content consistent as Dominican Casino evolves.

---

## 1. Core Product Principle

Dominican Casino is a **card game first**.

The Dominion Journey adds progression, personality, collectibles, and a light narrative around the existing card games. It must never become a requirement for someone who simply wants to open the app and play cards.

The player should be able to:

- Open the app.
- Select an unlocked card game.
- Play immediately.
- Earn XP naturally.
- Leave.

The Journey exists quietly alongside this loop.

Players who care about progression can engage deeply with it. Players who do not care can largely ignore it while still progressing naturally.

**Core rule:**

> The story gives playing cards meaning. It must never get in the way of playing cards.

---

## 2. Core UI Metaphor

Everything belongs to the language of a physical deck of cards.

The app already uses:

- Large cards for games.
- Stacked cards for navigation.
- Card-style scoreboards.
- Card-style store items.
- Themed card faces and backs.
- Horizontal swiping resembling cards being handled.

Dominion extends this metaphor rather than introducing a separate RPG-style interface.

### Games Deck

The primary deck.

When the Games Deck is expanded, the player horizontally browses unlocked games.

The Journey appears nearby as a smaller stacked deck.

### Journey / Dominion Deck

Tapping the Journey Deck causes:

1. The Games cards to collapse into a small deck.
2. The Journey deck to expand.
3. The current World to display its character cards horizontally.

The player is essentially choosing:

> **Which deck do I want on the table?**

No separate permanent navigation tab is required initially.

---

## 3. Progression Philosophy

There are three layers of progression.

### XP / Level

XP represents general experience.

XP is earned through normal play.

Players do **not** spend XP.

Normal games should award XP whether the player wins or loses, although winning should award meaningfully more.

This ensures:

> Losing does not feel wasted, but winning still matters.

Levels determine when new Journey challenges become available.

### Character Progression

At milestone levels, the player becomes eligible to challenge specific characters.

Defeating important characters unlocks their avatar.

The avatar therefore represents an accomplishment rather than simply a cosmetic purchase.

### World Progression

Each world belongs to one traditional playing-card suit:

1. ♦ Diamonds
2. ♣ Clubs
3. ♥ Hearts
4. ♠ Spades

Each world culminates in its King.

Defeating/resolving the world's royal progression ultimately earns the corresponding **Ace**.

The four Aces are the major progression artifacts:

- ♦ Ace of Diamonds
- ♣ Ace of Clubs
- ♥ Ace of Hearts
- ♠ Ace of Spades

Collecting all four unlocks the final chapter involving the Jokers.

---

## 4. Recommended Level Structure

Do **not** create 52 required story battles simply because a deck contains 52 cards.

Levels provide frequent progression.

Characters provide memorable milestones.

The exact XP numbers should remain tunable based on player behavior.

### Initial structure

#### Training — Level 0

The player begins with Dominican Casino.

Training teaches the core interaction naturally through a short introductory match.

Completing training:

- Reaches Level 1.
- Begins the Dominion Journey.
- Unlocks the first Journey challenger.
- Establishes that normal play earns XP.

The story introduction should be extremely light.

The player is simply a **Traveler** moving through the four realms.

They are not introduced as a legendary chosen hero.

---

## 5. World Structure

Each world follows approximately:

**Entry → Challenger(s) → Jack → Queen → King → Ace → Next World**

Not every encounter needs to be equally difficult or narratively important.

The Jack, Queen, and King are the major character cards and deserve the strongest art treatment.

Recommended initial pacing per world:

| Milestone | Encounter |
|-----------|-----------|
| Level N | Regular Challenger |
| Level N+1 | Regular Challenger |
| Level N+2 | Jack |
| Level N+3 | Queen |
| Level N+4 | King / World climax |
| Completion | Ace earned + next World unlocked |

This means the initial Journey can target roughly **20 meaningful progression levels**, rather than requiring 52 bespoke encounters.

The exact number of minor challengers can expand later without changing the underlying story.

---

## 6. Challenge Rules

Characters are opponents layered on top of the existing card games.

They are **not separate games**.

A character challenge launches one of Dominican Casino's actual card games.

Whenever practical, avoid permanently forcing players through a card game they dislike.

Possible challenge behavior:

- Some characters prefer a particular game.
- Some encounters teach newly unlocked games.
- Important encounters may offer a choice among unlocked games.
- Special characters can occasionally require a particular game when it serves onboarding or narrative progression.

Early Journey encounters can gradually introduce the four card games.

Once taught/unlocked, those games become independently playable from the Games Deck.

The Journey therefore acts partly as an organic tutorial.

---

## 7. The Four Worlds

The following personalities are **canon**.

Specific architecture, costumes, props, scenery, card backs, and decorative details remain flexible so existing themes can be incorporated.

### ♦ WORLD I — DIAMONDS

**Virtue:** Ambition (corrupted → Greed)

**Personality:** Sophisticated, wealthy, polished, confident, elegant, ordered, comfortable.

**Visual direction:** Violet, crystal, gold, faceted geometry, reflections, clean symmetry, luxury without excessive ornamentation.

**Narrative:** The Diamond Kingdom has been touched by the Dark Joker's influence, but subtly. Society still functions; corruption is easy to mistake for ordinary ambition. The Diamond King tests the Traveler by court tradition—not because he knows the Traveler's destiny.

**Reward:** ♦ Ace of Diamonds

### ♣ WORLD II — CLUBS

**Virtue:** Freedom (corrupted → Escape / recklessness)

**Personality:** Natural, free, adventurous, playful, organic, unstructured, alive.

**Visual direction:** Green, forests, wood, leaves, vines, sunlight, natural textures, organic asymmetry.

**Narrative:** Freedom is used as an excuse not to care. The Clubs King withdrew rather than confront disturbances. Through the Traveler's challenge he learns the difference between being free and running away.

**Reward:** ♣ Ace of Clubs

### ♥ WORLD III — HEARTS

**Virtue:** Love (corrupted → Possession / obsession)

**Personality:** Warm, joyful, romantic—until something is wrong underneath.

**Visual direction:** Dark red, burgundy, roses, vines, thorns, candlelight, warm interiors becoming oppressive.

**Narrative:** Affection has become appetite. The Heart King is the first major **false villain**—he tried to resist corruption, failed, and fell into despair. Defeating him restores enough clarity to reveal the darkness did not originate in Hearts.

**Reward:** ♥ Ace of Hearts

### ♠ WORLD IV — SPADES

**Virtue:** Strength / Power (corrupted → Pride / domination)

**Personality:** Severe, militaristic, broken, proud, cold, dangerous, exhausted by constant conflict.

**Visual direction:** Black, charcoal, silver, broken architecture, sharp silhouettes, ruined banners, visible evidence of prolonged conflict.

**Narrative:** Spades appears to be the obvious source of evil. It is not. The Spade King believes only strength prevents collapse after the other realms failed.

---

## 8. The Missing Queen of Spades

Spades deliberately breaks the progression pattern the player has learned.

By this point the player expects: **Challenger → Jack → Queen → King**

Instead the Queen is missing—damaged, face-down, empty, torn, or obscured. Do not immediately explain why.

After defeating the Jack, the expected Queen encounter does not occur. The Traveler proceeds toward the King.

---

## 9. King of Spades

Unlike previous Kings, the Spade King is **not merely testing the Traveler**. This confrontation is genuinely dangerous. The King has been heavily corrupted by pride and the need for absolute control.

The Traveler defeats him—but he does not possess the Ace. The Queen does.

---

## 10. Queen of Spades

The Queen opposed the King's corruption. She disappeared from the normal royal progression and protected the Ace of Spades.

After the King's defeat, the Traveler meets her. Her final match is intentionally easy, quiet, almost peaceful—testing whether the Traveler can **play without needing domination**.

**Reward:** ♠ Ace of Spades. All four Aces are now complete.

---

## 11. The Two Jokers

The Joker was once a single whole being that became divided.

- **Wild Joker:** Play, surprise, chance, humor, creativity—wildness without malice.
- **Dark Joker:** Chaos separated from balance; amplifies virtues until they become destructive.

The Dark Joker's influence is responsible for the gradual corruption visible throughout the Journey.

---

## 12. Why the Four Aces Matter

The Aces are **not keys that simply release the villain**. They represent mastery of the four suits and provide access to the imprisoned Wild Joker.

Only all four Aces together can reach the Wild Joker. The Traveler becomes worthy through the Journey—not by being secretly "the Chosen One."

---

## 13. Final Chapter — The Joker

After collecting all four Aces, the hidden final chapter becomes available. The four Aces reveal/release the Wild Joker.

For the final confrontation, the Traveler does not fight alone—**the Wild Joker plays alongside the Traveler**. The ultimate objective is restoration, not annihilation.

---

## 14. The Final Card

The two Joker cards visually complement one another. Each alone appears intentionally incomplete; placed together their illustrations connect. **The deck becomes whole.**

The conclusion is not "good destroys evil" but: power, ambition, love, freedom, and chaos become destructive when pushed beyond balance.

---

## 15. Journey UI Map

Only one World needs to be expanded at a time.

Example when ♦ Diamonds is expanded:

```
[✓ Challenger] [✓ Challenger] [JACK] [QUEEN] [KING] [ACE]
```

Below: ♣ Clubs (stacked), ♥ Hearts (locked stack), ♠ Spades (locked stack).

Selecting an unlocked World collapses the current one and expands the selected world's character cards horizontally.

Completed worlds remain revisit-able. Locked future worlds preserve mystery.

---

## 16. Character Card States

| State | Treatment |
|-------|-----------|
| **Defeated** | Character visible, completion indicator, avatar unlocked, replayable |
| **Current / Available** | Prominent, clear **Challenge** action |
| **Level Locked** | Visible or partially obscured; simple requirement (e.g. "Reach Level 8") |
| **Mystery Locked** | Identity hidden; used for future worlds, missing Queen of Spades, Joker chapter |

---

## 17. Avatars

Avatars are primarily **earned identity**.

- Each theme pack starts with **one** free painted avatar.
- Journey face cutouts (Jack, Queen, King, Ace) unlock when that challenger is defeated or the Ace is claimed, and stay usable while that world’s theme is equipped.
- Painted extras unlock by player level: Base `leaf`@5 / `star`@10; Diamonds `acorn`@5; Clubs `leaf`@10; Hearts `sun`@15; Spades `moon`@20.
- Profile Looks shows unlocked avatars plus a locked stack for the rest.

Do not immediately add large parallel collectible systems (badges, gems, stickers, equipment, pets, multiple cosmetic currencies).

---

## 18. Coins and Energy

- **Energy:** Controls how much the player can play within a period; regenerates.
- **Coins:** Primarily buy additional energy when the player wants to continue. Coins should not gate the main Journey.
- **XP:** Cannot be purchased or spent.

**Coins = flexibility. Energy = opportunity to play. XP = progress. Aces = world mastery. Avatars = accomplishments.**

---

## 19. Normal Games vs Journey

| Mode | Flow |
|------|------|
| **Normal play** | Games Deck → unlocked game → play → earn XP |
| **Journey** | Journey Deck → current World → character → challenge (same underlying games) |

A casual player can ignore the Journey and still level naturally.

---

## 20. Story Delivery Rule

**Never dump this document onto the player.**

Story is communicated through character art, world changes, card design, very short dialogue, missing/altered cards, environmental clues, and progression structure.

---

## 21. Art Direction Hierarchy

**Highest detail:** Jack, Queen, King, Ace, Jokers — define each World.

**Medium detail:** Regular Journey challengers — memorable but can share templates.

**Reusable system:** Consistent character-card proportions, typography, suit positioning, silhouette rules, frame structure, lock/progress states.

Assets live under `assets/images/journey/`. Source composite sheets are kept in `assets/images/journey/source/`.

---

## 22. World Art Summary

| Suit | Virtue | Corruption | Core Feeling | Visual Direction |
|------|--------|------------|--------------|------------------|
| ♦ Diamonds | Ambition | Greed | Sophisticated / prosperous | Violet, crystal, gold, geometry |
| ♣ Clubs | Freedom | Escape / recklessness | Natural / adventurous | Green, wood, leaves, organic forms |
| ♥ Hearts | Love | Possession / obsession | Warm → unsettling | Burgundy, roses, vines, thorns |
| ♠ Spades | Strength | Pride / domination | Fallen / militaristic | Black, silver, ruins, sharp forms |
| 🃏 Joker | Chaos / play | Chaos without balance | Unpredictable | Breaks established visual rules |

---

## 23. Narrative Escalation

1. **Diamonds:** "This world is interesting." — Learn the Journey.
2. **Clubs:** "There may be more happening here."
3. **Hearts:** "Something is wrong." — First false villain revealed as victim.
4. **Spades:** "This must be where the evil came from." — Structure breaks; Queen missing.
5. **Queen of Spades:** "We misunderstood the problem."
6. **Joker:** "The Journey was about restoring balance."

---

## 24. Scope Guardrails

Before adding a Journey feature, ask:

- Does this make playing the existing card games more meaningful?
- Can a player who doesn't care about the Journey ignore it?
- Does this require another currency? (Probably don't.)
- Does this require another permanent navigation destination? (Probably don't.)
- Can this concept be represented as a card, deck, hand, flip, deal, shuffle, or stack?
- Does the feature need explanation before it is fun? (Simplify it.)

---

## 25. Canon That Should Not Change Casually

1. Dominican Casino remains a card-game-first experience.
2. The Journey is optional progression layered onto the games.
3. Worlds follow ♦ Diamonds → ♣ Clubs → ♥ Hearts → ♠ Spades.
4. Each suit represents a positive quality that has a corrupted extreme.
5. XP is earned through normal play.
6. Levels unlock Journey encounters.
7. Characters are fought through the existing card games.
8. Defeating characters can unlock their avatars.
9. Each World culminates in obtaining its Ace.
10. The Heart King appears villainous but is corrupted/despairing rather than inherently evil.
11. Spades is a fallen kingdom.
12. The Spade King represents corrupted pride, control, and domination.
13. The Queen of Spades is deliberately missing from the expected progression.
14. The Queen secretly protects the Ace of Spades.
15. Her final match tests restraint rather than raw strength.
16. Four Aces unlock the final Joker chapter.
17. There are two Jokers representing divided halves of one whole.
18. The Dark Joker corrupted the virtues of the four suits.
19. The Wild Joker represents playful, constructive chaos.
20. The final resolution reunites the Jokers rather than simply destroying one.
21. The final paired Joker cards form one complete illustration.
22. The deck is restored to balance.

Everything else—including names, architecture, costumes, exact dialogue, number of minor challengers, XP values, game assignments, and detailed mythology—can evolve.

---

## 26. One-Sentence Product Story

> **Play familiar card games, grow through four kingdoms of the deck, defeat their challengers, collect the four Aces, and discover what has thrown the deck out of balance.**

---

## 27. Internal North Star

> **Play first. Progress naturally. Discover if curious.**

---

## 28. Implementation Notes (engineering)

### Journey UI map (current)

Three bands on the Journey table:

1. **Top — World piles:** four face-down stacks (♦ ♣ ♥ ♠). Locked piles show backs only (no character art). Unlocked pile top card is selectable.
2. **Center — Active stage:** empty hint, or selected challenger (game-card + Challenge) with Rewards peek to the right.
3. **Bottom — Defeated:** four slots for beaten challengers per world (replay later).

Selecting a challenger flips/scales into center. Challenge dialog offers **Play** (local bot match for the card's game), plus **Defeat** / **Lose** debug shortcuts. Wins persist defeat progress; losses show a challenger taunt. Journey progress is stored locally.

### Theme system (Base + four worlds)

Five themes. Enum IDs kept for persistence; product names remapped:

| Enum | Product name | Unlock |
|------|--------------|--------|
| `Theme.sage` | Base | free |
| `Theme.casino` | Diamonds | play (Journey) |
| `Theme.dune` | Clubs | play |
| `Theme.fig` | Hearts | play |
| `Theme.midnight` | Spades | play |

Coin theme sales are retired (`coinPacksForSale` is empty). Profile shows play-locked packs with a Journey lock until unlocked.

**Equip rules:**

- Entering Journey always unlocks (if needed) and equips the **active world** theme — even if the player had switched back to Base in Profile.
- Selecting an unlocked world pile equips that world’s theme (same as Profile picker).
- Base remains available in Profile as a temporary escape.

`AppRepo.unlockAndEquipPack` is the shared entry point. `JourneyWorld.themeId` maps world → Theme.

### v1 Diamonds pacing

| Character | Unlock level | Game |
|-----------|--------------|------|
| Jack | 2 | Tres y Dos |
| Queen | 2 | Rummy |
| King | 2 | Casino Speed |

Defeating the King grants the Ace and unlocks the next world / theme.

### Explicitly later

Spades Queen twist, Joker chapter, accent intensity ramps (Jack→King→Ace), Firestore mirror of Journey progress.
