# Wildwell 1.6

A runnable native SwiftUI iOS app with wellbeing lessons, real-world practices, a visual mood calendar, and collectible animal characters. Works offline without third-party dependencies, accounts, API keys or servers.

## Run or update

1. Open **Wildwell.xcodeproj** in Xcode 15 or later (validated using Xcode 27.2). Package.swift is for core tests, not the runnable app.
2. Choose the **Wildwell** scheme and an iPhone/iPad simulator running iOS 17+.
3. Press **⌘R**.

For your phone, select it in Xcode, keep it connected/unlocked with Developer Mode enabled, and use your team with automatic signing under Signing & Capabilities. Press ⌘R.

**To retain your existing data:** run this project over the existing app using the same bundle identifier and signing team. Do not uninstall the old app. This project retains your existing signing settings and `Documents/wildwell-v1.json`. Export/back up important journal entries before an update.

## What's new in 1.6

- **Today** shows one ready-to-try activity for the chosen intention and 1, 3, or 5 minutes. A quick practice can be completed before its full guide. It still gives the same world-specific reward, and the full guide remains available in its world.
- **Check in** is available on Today. Choose a feeling and save, or expand **Add a detail** for an optional factor or note. Backdating remains available from the Mood calendar and in the regular check-in form.
- **Mood → Week** shows counts for factors you chose to record, with a link to the matching entries from the displayed week.
- **Collection → Field guide** has a page for each world, showing found species and owned rarities. Open an owned card to read its wildlife fact.
- Copies of the same species and rarity cycle through Daylight, Sunset and Moonlight illustrated editions. Each copy keeps its edition and illustrative size in reveals, history and PNG sharing.

## Daily check-in and shareable cards

- On the first open or return to Wildwell each local day, the optional check-in appears after any first-run welcome. Skip it freely or log today's mood later in Mood.
- The first new entry recorded for today earns one surprise card from the full 12-animal pool, using the same rarity odds and reveal animations as practices. Additional entries, edits and backdated check-ins do not give additional cards.
- Tap the small share icon after revealing an animal or in its Collection detail. The native share sheet exports a PNG with the artwork, species, rarity, world and illustrative size. Mood entries and notes are kept out of the image.
- Every copy has a stable simulated measurement, including older copies. The measurement type fits the animal, such as tail length or wingspan. The field guide retains the real species reference facts.

## New reward loop

**Learn → complete any wellbeing practice → automatically receive a random animal character → optionally reflect.**

- Every successful practice completion awards **one new character instance**, including repeat activities, timer completions, and confirmed manual completions.
- The animal is chosen uniformly from the **three species in the completed practice’s study world**. There are twelve real species across four worlds; rewards no longer cross world pools.
- Rarity is chosen independently: **Rare / blue: 70%**, **Epic / purple: 25%**, **Myth / red: 5%**.
- The award is saved alongside its practice before the reveal. Tap its glowing seal to uncover the animal: Rare takes one tap, Epic two, and Myth three. The animal stays hidden until the sequence ends. These taps reveal an already-owned character; they never reroll it or claim a second award.
- The same animal in different rarities occupies different collection cards. There are **36 possible animal-and-rarity combinations**.
- Exact duplicates add to that card's copy count. Each copy retains its own identifier, date, and originating practice; none are discarded.
- The collection is a dedicated tab. Today contains no animal collection grid, locked silhouettes, completion meter, or pending-reward banner; learning worlds use compact text/icon cards.
- The Collection tab supports animal search, study-world and rarity filters, variant detail cards, copy history and source-linked real-species information.
- Interrupted arrival screens remain available for review inside Collection. Their rewards are already owned and do not need to be claimed again.
- Odds are visible in Collection → How character rewards work. There are no purchases, paid draws, rarity upgrades, re-roll buttons, or expiring characters. Reporting a mood, choosing a longer activity, or using a gentler alternative does not change the odds.

Rarity is a cosmetic game label. It says nothing about an animal's real conservation status or a user's wellbeing.

### Existing save migration

Each earlier unique species discovery becomes one **Rare** character, preserving its original date. Earlier interrupted discoveries become pending arrival reviews. Old practices, moods, reflections, favourites and active timers are retained. Previously awarded Rare/Epic/Myth characters are never recoloured, removed or rerolled when the pool rules change. Migration is saved once; reopening the app does not duplicate or reroll migrated characters. Older practices are not retroactively assigned random rewards.

## New reveal animations

- **Rare / blue:** one tap, six blue/cyan stars with a gentle spring bounce.
- **Epic / purple:** two taps, twelve purple/lilac stars rotating into a springing spiral.
- **Myth / red:** three taps, eighteen crimson/gold stars with expanding rings and a stronger spring burst.

No timed tapping or rapid gestures are required. **Reveal without animation** is always available, and system Reduce Motion removes animated movement. Animation state may restart if the view is closed; the already-saved character and rarity remain unchanged. Native back navigation lets you leave; pending arrivals can be reopened in Collection.

## Improved learning experience

Each guide saves its step, selected example and answer locally. All examples remain compact, full-card choices, with the selected explanation below them; reading-step changes are immediate to avoid overlapping text during interaction. Closing the app mid-guide lets you return with **Resume guide**. Sticky bottom controls keep Continue/Back in reach, the progress strip identifies the current stage, and moving to the next stage returns to the top of that page. Wrong answers provide feedback without penalties; a correct answer is followed by an explicit Finish lesson action. Lessons do not award characters by themselves.

The chosen practice, duration and gentler preference carry into the challenge. The final guide summary explains the next step and its study-world reward pool. World details list the three possible animals and rarity odds without showing collection progress on Today.

## Wellbeing worlds

| World | Focus | Practices |
|---|---|---|
| Cloud Forest | Physical wellbeing | Noticing walk; desk movement; kinder wind-down plan |
| Quiet Coast | Mental wellbeing | Notice details; one task at a time; park a busy thought |
| Kindred Woods | Social wellbeing | Kindness; a boundary; where you belong |
| Feeling Wetlands | Emotional wellbeing | Make space for a feeling; kinder sentence; name a small need |

Each world has one guided lesson and three practice choices. The five lesson stages are Notice, Explore, Make a plan, Check your idea, and Ready to try. Explore interactive examples, choose a practice, set a comfortable duration/gentler version, and answer a knowledge check with explanatory feedback. Completing the guide carries your chosen practice and preferences directly into the activity. Complete its lesson once; return directly to practice afterwards. Choose 1, 3, 5 or 10 minutes and an original or gentler activity. The optional timer supports pause/resume and survives closing the app. Self-reported completion is explicitly confirmed. Ending an unfinished activity gives no reward and removes only that active timer.

Today remembers your chosen intention, available time and gentler preference. Favourites are available in Practise. Suggestions to revisit useful worlds use your explicit reflection feedback, not inferred health data.


### Reward pools

| Study section | World | Animals |
|---|---|---|
| Physical wellbeing | Cloud Forest | Red panda; Linnaeus’s two-toed sloth; ring-tailed lemur |
| Mental wellbeing | Quiet Coast | Sea otter; green sea turtle; bat ray |
| Social wellbeing | Kindred Woods | Red fox; great horned owl; eastern cottontail |
| Emotional wellbeing | Feeling Wetlands | Axolotl; American bullfrog; great blue heron |

Pools are creative game-world groupings. Real habitats and distributions are explained in the species cards. Every animal from earlier versions is retained, including rewards originally earned under the old cross-world rules. New rewards record their originating study world.

## Mood calendar

The **Mood** tab contains month/week calendars, selectable days, a weekly chart, monthly category counts and optional check-ins. Each day shows its latest recorded mood symbol plus dots for additional entries. Its detail lists every feeling, time, factor, note and related activity/reflection.

You can log past moments and edit existing entries. Dates follow the device's current calendar/time zone, using Calendar arithmetic across daylight-saving changes. Future entries are not accepted. The weekly plot uses labelled feeling categories, with no numerical wellbeing score or interpolated line. Empty days remain unrecorded; no mood is inferred. Activities are shown as context, not as proof of what caused a feeling.

Wildwell keeps the mood calendar local and check-in rewards are independent of the mood selected. Reflection and check-ins remain optional.

## Privacy and persistence

A main-actor `@Observable` store drives all tabs. Codable state is saved atomically with iOS file protection. Every character instance, its rarity, copy history and review state persist in the same local save as your wellbeing records.

No network requests or analytics. Source links open a browser only when tapped. Export uses the native share sheet, with private moods/notes/reflections excluded unless you explicitly include them. Data may be included in device backups; this is not a separate encrypted vault. Deleting the app removes its local data.

Failed saves display a retry option. An unreadable save is preserved before a fresh recovery save is written.

## Tests

From this directory:

```sh
swift test
```

This runs the Foundation/Observation core suite on macOS 14+. It checks rarity boundaries and exact probability buckets, every animal/rarity combination, repeat rewards, exact duplicate copies, single-session completion guards, timer/manual parity, persistence, original-save migration, journal/export privacy, mood-calendar dates and editing, daily reward rollover, and copy measurements.

In Xcode, choose **Product → Test (⌘U)** to run the learning/reward journey, rarity-reveal sequences, mood-calendar UI tests, and the daily reward and share-sheet flow. Debug UI tests use a separate UUID-named journal and do not reset personal data. The main learning/reward UI journey uses live randomness and checks that animals belong to its study world. A separate animation test uses an explicit Debug-only fixture for each rarity to verify all tap sequences and the bypass. This hook requires a fresh UUID test journal, is not a user-facing mode, and is excluded from Release builds.

Command-line simulator build:

```sh
xcodebuild -project Wildwell.xcodeproj -scheme Wildwell \
  -sdk iphonesimulator -configuration Debug \
  -derivedDataPath .build-ios CODE_SIGNING_ALLOWED=NO build
```

See VALIDATION.md for checks actually performed and their limits.

## Previews and limits

`Today.png`, `Preview.png`, `Discovery.png`, `CharacterDetail.png`, `Learning.png`, `LearningPlan.png`, and rarity reveal screenshots are simulator captures using isolated test records. `RarityPreview.png` is a clearly labelled design preview rendered with the same character artwork code, showing blue/purple/red variants; it is not seeded collection data. Mood screenshots also use test entries. A fresh install starts empty.

This remains a small MVP with four introductory lessons, twelve practices and twelve animal species. No cloud sync, reminder scheduling, HealthKit, location tracking, social accounts or automatic message sending. The timer has no background alarm; device-clock changes can affect its elapsed time. Manual completions are self-reported. The updated version has not been tested on physical hardware.

Species facts were checked in November 2026 against the references below. Size varies by population and individual. Rarity colours are stylistic overlays; original cartoon anatomy/colours are simplified and are not identification diagrams. The pale axolotl represents a captive colour form. Real conservation status is not inferred from a character's rarity. World themes are creative learning maps; reward pools are specific to each study world, and species cards describe actual habitats.

## Species sources

- [Red panda — Smithsonian](https://www.nationalzoo.si.edu/animals/red-panda)
- [Linnaeus’s two-toed sloth — Smithsonian](https://nationalzoo.si.edu/animals/two-toed-sloth)
- [Ring-tailed lemur — Smithsonian](https://nationalzoo.si.edu/animals/ring-tailed-lemur)
- [Sea otter — Monterey Bay Aquarium](https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/sea-otter)
- [Green sea turtle — Monterey Bay Aquarium](https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/green-turtle)
- [Bat ray — Monterey Bay Aquarium](https://www.montereybayaquarium.org/animals-the-ocean/animals-a-to-z/bat-ray)
- [Red fox — University of Michigan](https://animaldiversity.org/accounts/Vulpes_vulpes/)
- [Great horned owl — University of Michigan](https://animaldiversity.org/accounts/Bubo_virginianus/)
- [Eastern cottontail — University of Michigan](https://animaldiversity.org/accounts/Sylvilagus_floridanus/)
- [Axolotl — American Museum of Natural History](https://www.amnh.org/explore/ology/ology-cards/366-axolotl)
- [American bullfrog — University of Michigan](https://animaldiversity.org/accounts/Lithobates_catesbeianus/)
- [Great blue heron — University of Michigan](https://animaldiversity.org/accounts/Ardea_herodias/)

Species facts are paraphrased. All illustrations are original code-drawn artwork; no source photographs are bundled. Wellbeing notes are general educational prompts without clinical-outcome claims.
