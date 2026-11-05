# Wildwell 1.6 validation — 6 November 2026

Xcode 27.2 and the iPhone 18 Pro simulator running iOS 27.2.

- The simulator build passed.
- All 22 Swift core tests passed, including reopening a one-minute quick practice and cycling and preserving duplicate backdrops.
- The final simulator walkthrough passed for Today, a quick practice and world-specific reward, the compact check-in, weekly recap drill-down, and opening a species card from a world guide.
- The final daily reward and share-sheet walkthrough passed, including reopening the saved card from its world guide.
- The mood calendar logging, editing, and weekly chart regression passed during the first simulator run.

Physical iPhone installation was outside this test run.

---

## Wildwell 1.5 validation — 6 November 2026

Xcode 27.2 and the iPhone 18 Pro simulator running iOS 27.2.

- The iOS Simulator build passed.
- The 21 core tests passed, including once-per-day prompting and rewards, reopening with the same reward, calendar rollover, and stable species-bounded copy sizes.
- The learning and collection journey, rarity reveal sequences, and mood calendar UI regressions passed.
- The daily check-in UI test passed. It opened the native image share sheet from a new reward, relaunched without another prompt, and confirmed the saved card still had its share action in Collection.

Physical iPhone installation and third-party share destinations were outside this test run.

---

## Wildwell 1.4 validation — 5 November 2026

Environment: Xcode 27.2 / Apple Swift 6.4.2; iPhone 18 Pro simulator running iOS 27.2.

## Results

- iOS Simulator build: **passed**.
- Core suite: **19 passed, 0 failures**.
- Learning, live world-specific rewards and collection persistence UI journey: **passed**, final strengthened run 110.3 seconds.
- Rare/Epic/Myth tap sequences plus animation bypass UI test: **passed**, 66.1 seconds.
- Mood-calendar UI regression: **passed**, 55.5 seconds.

The reveal and mood tests passed in the initial complete suite. Screenshot review then exposed an insufficiently checked lesson selection during a text transition. Lesson choices were changed to compact, full-card hit targets with immediate reading-step transitions and explicit draft saving. The main learning journey was rerun with exact assertions for the saved plan and the challenge title; it passed on the final implementation. The later changes were limited to lesson selection/reading controls and challenge option hit areas.

## Core coverage

- Each world draws only from its own three-species pool; every local animal and all rarities can be produced (36 variants across four worlds).
- New rewards record their originating study world. Old cross-world characters remain unchanged.
- Every successful challenge, including repeats, awards one character; a consumed session cannot award twice.
- Rarity boundaries remain exactly 70% Rare, 25% Epic and 5% Myth.
- Duplicate copy identity/counts, pending reviews, save migration, reflection persistence and private export exclusion.
- Lesson drafts retain the selected example, step and answer, reject invalid/out-of-world choices, and cannot mark a lesson complete before its learning state is complete.
- Timer/manual completion parity, favourites and original saved progress.
- Mood editing, future-date rejection, leap months and Sydney's 23-/25-hour daylight-saving days.

## UI coverage

### Main learning/reward journey

Welcome → choose physical wellbeing → open guide → explore and select “Uncurl from your desk” → terminate/relaunch → Resume guide → assert the plan still names “Uncurl from your desk” → choose one minute and gentler version → try a wrong knowledge-check answer (no completion) → correct answer → Finish lesson → assert the actual challenge title matches the saved plan → timer start/pause and confirmed manual completion → tap to reveal a forest animal → repeat practice and receive another forest animal → search/view Collection → relaunch with both saved characters retained.

This journey uses live randomness. Its assertions accept only red panda, Linnaeus’s two-toed sloth or ring-tailed lemur for the forest world.

### Rarity reveals

A separate Debug-only test fixture, isolated behind a fresh UUID test journal, selects each rarity so all three sequences can be exercised without relying on chance:

- Rare: animal hidden until tap 1.
- Epic: animal hidden after tap 1, revealed after tap 2.
- Myth: animal hidden after taps 1 and 2, revealed after tap 3.
- Reveal without animation opens the already-saved character without repeated taps.

Fixture setup is excluded from Release builds and is not a user-facing mode. The normal app uses independent system-random animal and rarity draws. Awards are persisted before the reveal; revealing does not draw again.

### Mood regression

Multiple same-day entries, a backdated entry, editing, month/week calendar and chart, navigation boundaries and persistence after relaunch.

## Visual review and previews

Reviewed actual simulator screenshots of the final compact example choices, the correct carried-over practice plan, and Myth sealed/opened reveal states. All three rarity styles have sealed/opened simulator captures in the project folder. Stars use finite spring transitions driven by taps; no perpetual animation loop is used.

- `Learning.png` and `LearningPlan.png`: final lesson UI with test-selected activity.
- `RareReveal.png`, `EpicReveal.png`, `MythReveal.png`: unopened rarity sequences.
- Corresponding `*Character.png`: opened character states.
- `Today.png`, `Preview.png`, `Discovery.png`, `CharacterDetail.png`: actual simulator test records.
- Mood previews are simulator records from the regression test.
- `RarityPreview.png` and `AnimalGallery.png` are labelled artwork overviews, not seeded collection progress.

## Limits

This update has not been tested on physical hardware. Haptic feel, all supported iOS versions, iPad, landscape and a full manual VoiceOver/large-text audit remain outstanding. Reduced-motion handling and a no-animation reveal option are implemented; the bypass was exercised in the UI test, while the OS Reduce Motion setting was not separately toggled during this run.

The app still has four short guides, twelve practices and twelve real species. World pools are game themes, not precise geographic ecosystems. Rarity is cosmetic rather than conservation status. No cloud sync, HealthKit connection, clinical assessment, paid draws, trading or timer alarm. Existing characters are preserved even if they were earned under older cross-world rules. Updating with the same bundle identifier/signing team and retaining the installed app preserves access to the local save.
