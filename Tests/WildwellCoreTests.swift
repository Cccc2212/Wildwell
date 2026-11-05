import XCTest
@testable import WildwellCore

final class WildwellCoreTests: XCTestCase {
    func testTimerPauseResumeAndClockChange() {
        let start = Date(timeIntervalSince1970: 1_000)
        var timer = WalkSession(worldID: "forest", target: 300)
        timer.resume(at: start)
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(40)), 40)
        timer.pause(at: start.addingTimeInterval(40))
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(200)), 40)
        timer.resume(at: start.addingTimeInterval(200))
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(230)), 70)
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(900)), 300)
        XCTAssertEqual(timer.elapsed(at: start.addingTimeInterval(100)), 40)
    }
    @MainActor func testCompletionRequiresLearningAndMatchingSession() throws {
        let store = WildStore(file: temporaryFile())
        let world = Catalog.worlds[0]
        store.begin(world, minutes: 1)
        XCTAssertNil(store.complete(world, manual: true))
        store.learn(world.id)
        XCTAssertNil(store.complete(world, manual: false))
        XCTAssertNil(store.complete(Catalog.worlds[1], manual: true))
        XCTAssertNotNil(store.complete(world, manual: true))
        XCTAssertNil(store.complete(world, manual: true))
        XCTAssertEqual(store.state.practices.count, 1)
    }
    @MainActor func testQuickPracticeAndDuplicateBackdropPersistence() throws {
        let file = temporaryFile()
        let world = Catalog.worlds[0]
        let draw: (Int) -> RewardDraw = { _ in RewardDraw(speciesIndex: 0, rarityRoll: 0) }
        let store = WildStore(file: file, drawReward: draw)
        let option = store.quickOption(in: world, minutes: 1)
        XCTAssertEqual(option.id, "forest-2")
        store.begin(world, minutes: 1, optionID: option.id, quickStart: true)
        let reopened = WildStore(file: file, drawReward: draw)
        XCTAssertEqual(reopened.state.session?.target, 60)
        XCTAssertNotNil(reopened.complete(world, manual: true))
        XCTAssertNil(reopened.complete(world, manual: true))
        XCTAssertFalse(reopened.state.learned.contains(world.id))
        for _ in 0..<3 {
            reopened.begin(world, minutes: 1, optionID: option.id, quickStart: true)
            XCTAssertNotNil(reopened.complete(world, manual: true))
        }
        let saved = WildStore(file: file, drawReward: draw)
        XCTAssertEqual(saved.rewards.reversed().map(\.backdrop), [.daylight, .sunset, .moonlight, .daylight])
        XCTAssertEqual(saved.variants.count, 1)
    }

    @MainActor func testRepeatRewardsCopiesReflectionAndExportPersistence() throws {
        let file = temporaryFile()
        let world = Catalog.worlds[0]
        let store = WildStore(file: file, drawReward: { _ in RewardDraw(speciesIndex: 0, rarityRoll: 80) })
        store.learn(world.id); store.begin(world, minutes: 1)
        let id = try XCTUnwrap(store.complete(world, manual: true))
        store.reflect(id, text: "Noticed leaves", helpful: "Not today")
        store.checkIn(mood: "Low", factor: "Study", note: "Private note", date: Date(timeIntervalSince1970: 1_700_000_000))
        let reward = try XCTUnwrap(store.rewards.first)
        XCTAssertEqual(reward.rarity, .epic)
        XCTAssertEqual(reward.practiceID, id)
        store.begin(world, minutes: 1)
        XCTAssertNotNil(store.complete(world, manual: true))
        XCTAssertEqual(store.rewards.count, 2)
        XCTAssertEqual(store.variants.count, 1)
        XCTAssertEqual(store.variants.first?.copies.count, 2)
        XCTAssertEqual(Set(store.rewards.map(\.id)).count, 2)
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.rewards.count, 2)
        XCTAssertEqual(reopened.pendingRewards.count, 2)
        XCTAssertEqual(reopened.state.practices.last?.reflection, "Noticed leaves")
        XCTAssertFalse(reopened.progressExport.contains("Private note"))
        XCTAssertTrue(reopened.progressExport.contains("Epic ×2"))
        XCTAssertTrue(reopened.privateExport.contains("Private note"))
        XCTAssertEqual(reopened.rewards.last?.id, reward.id)
    }

    @MainActor func testActiveTimerPersistsAndCannotBeReplaced() {
        let file = temporaryFile()
        let store = WildStore(file: file)
        store.begin(Catalog.worlds[0], minutes: 5); store.toggleTimer()
        store.begin(Catalog.worlds[1], minutes: 1)
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.state.session?.worldID, "forest")
        XCTAssertNotNil(reopened.state.session?.startedAt)
        reopened.toggleTimer()
        XCTAssertNil(reopened.state.session?.startedAt)
        reopened.cancelSession()
        XCTAssertNil(WildStore(file: file).state.session)
    }
    @MainActor func testEveryWorldAndEveryRepeatAwardsOneCharacter() {
        let store = WildStore(file: temporaryFile())
        for world in Catalog.worlds {
            store.learn(world.id)
            for _ in 0..<4 {
                store.begin(world, minutes: 1)
                XCTAssertNotNil(store.complete(world, manual: true))
                XCTAssertNil(store.complete(world, manual: true))
            }
        }
        XCTAssertEqual(store.rewards.count, 16)
        XCTAssertEqual(store.state.practices.count, 16)
        XCTAssertEqual(store.pendingRewards.count, 16)
    }

    @MainActor func testUnreadableSaveIsPreservedBeforeRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("wildwell-recovery-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("wildwell-v1.json")
        let original = Data("invalid saved data".utf8)
        try original.write(to: file)
        let store = WildStore(file: file)
        XCTAssertNotNil(store.storageError)
        store.learn("forest")
        XCTAssertEqual(try Data(contentsOf: file), original)
        store.retrySave()
        XCTAssertNil(store.storageError)
        let backup = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first { $0.lastPathComponent.hasPrefix("wildwell-recovery-") })
        XCTAssertEqual(try Data(contentsOf: backup), original)
        XCTAssertTrue(WildStore(file: file).state.learned.contains("forest"))
    }
    @MainActor func testEveryWorldDrawsOnlyItsOwnAnimalsWithAllRarities() {
        var index = 0
        var roll = 0
        var poolSizes: [Int] = []
        let store = WildStore(file: temporaryFile(), drawReward: { poolSize in
            poolSizes.append(poolSize)
            return RewardDraw(speciesIndex: index, rarityRoll: roll)
        })
        for world in Catalog.worlds {
            store.learn(world.id)
            for localIndex in world.speciesPool.indices {
                index = localIndex
                for rarityRoll in [0, 70, 95] {
                    roll = rarityRoll
                    store.begin(world, minutes: 1)
                    XCTAssertNotNil(store.complete(world, manual: true))
                    XCTAssertEqual(store.rewards.first?.speciesID, world.speciesPool[localIndex].id)
                    XCTAssertEqual(store.rewards.first?.originWorldID, world.id)
                }
            }
        }
        XCTAssertEqual(store.rewards.count, 36)
        XCTAssertEqual(store.variants.count, 36)
        XCTAssertTrue(poolSizes.allSatisfy { $0 == 3 })
    }
    @MainActor func testLegacySaveMigrationPreservesProgressAndTimer() throws {
        let file = temporaryFile()
        var legacy = SavedState()
        legacy.learned = ["forest"]
        legacy.discoveries = ["panda": Date()]
        legacy.practices = [Practice(worldID: "forest", method: "Self-reported", seconds: 0)]
        legacy.session = WalkSession(worldID: "ocean", target: 180, accumulated: 10)
        legacy.welcomed = true
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any])
        json.removeValue(forKey: "preferences"); json.removeValue(forKey: "pendingQueue")
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let store = WildStore(file: file, drawReward: { _ in RewardDraw(speciesIndex: 1, rarityRoll: 99) })
        XCTAssertNil(store.storageError)
        XCTAssertEqual(store.rewards.first?.rarity, .rare)
        XCTAssertEqual(store.state.discoveries.count, 1)
        XCTAssertEqual(store.state.session?.accumulated, 10)
        XCTAssertEqual(store.preferences.minutes, 3)
        XCTAssertTrue(store.didPractise(Catalog.worlds[0].options[0], in: Catalog.worlds[0]))
        store.cancelSession()
        store.begin(Catalog.worlds[0], minutes: 1, optionID: "forest-2")
        XCTAssertNotNil(store.complete(Catalog.worlds[0], manual: true))
        XCTAssertNotNil(store.state.discoveries["sloth"])
        XCTAssertNotNil(WildStore(file: file).state.discoveries["panda"])
    }
    @MainActor func testQueuedRewardsAndPreferencesSurviveRelaunch() throws {
        let file = temporaryFile()
        let store = WildStore(file: file)
        store.setMinutes(1); store.setIntention("forest"); store.setGentler(true); store.toggleFavourite("forest")
        for world in Catalog.worlds.prefix(2) {
            store.learn(world.id); store.begin(world, minutes: 1); _ = store.complete(world, manual: true)
        }
        let ids = store.pendingRewards.map(\.id)
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.pendingRewards.map(\.id), ids)
        reopened.acknowledgeReward(ids[1])
        XCTAssertEqual(reopened.pendingRewards.map(\.id), [ids[0]])
        reopened.acknowledgeReward(ids[0])
        XCTAssertTrue(reopened.pendingRewards.isEmpty)
        XCTAssertEqual(reopened.rewards.count, 2)
        XCTAssertEqual(reopened.preferences.minutes, 1)
        XCTAssertTrue(reopened.preferences.gentler)
        XCTAssertTrue(reopened.preferences.favourites.contains("forest"))
        XCTAssertEqual(reopened.suggestedWorld.id, "forest")
    }

    @MainActor func testUsefulSuggestionsOnlyReflectUserFeedback() throws {
        let store = WildStore(file: temporaryFile())
        let world = Catalog.worlds[0]
        store.learn(world.id); store.begin(world, minutes: 1)
        let id = try XCTUnwrap(store.complete(world, manual: true))
        XCTAssertTrue(store.usefulWorlds.isEmpty)
        store.reflect(id, text: "Not for me", helpful: "Not today")
        XCTAssertTrue(store.usefulWorlds.isEmpty)
        store.reflect(id, text: "Useful this time", helpful: "Yes")
        XCTAssertEqual(store.usefulWorlds.map(\.id), [world.id])
    }
    func testMoodCalendarLeapMonthAndWeekdayAlignment() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.firstWeekday = 2
        let february = calendar.date(from: DateComponents(year: 2024, month: 2, day: 14))!
        let cells = MoodCalendar.cells(in: february, calendar: calendar)
        XCTAssertEqual(cells.count % 7, 0)
        XCTAssertEqual(cells.compactMap { $0 }.count, 29)
        XCTAssertNil(cells[0]); XCTAssertNil(cells[1]); XCTAssertNil(cells[2])
        XCTAssertEqual(calendar.component(.day, from: try XCTUnwrap(cells[3])), 1)
        let week = MoodCalendar.week(containing: february, calendar: calendar)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(calendar.component(.weekday, from: week[0]), 2)
    }
    func testMoodDayGroupingAcrossSydneyDaylightSaving() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        for (month, day, hours) in [(10, 4, 23), (4, 5, 25)] {
            let start = calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            XCTAssertEqual(end.timeIntervalSince(start), Double(hours * 3600))
            let entries = [
                CheckIn(date: start.addingTimeInterval(-1), mood: "Tired", factor: "Sleep", note: "Before"),
                CheckIn(date: start, mood: "Low", factor: "Work", note: "Start"),
                CheckIn(date: end.addingTimeInterval(-1), mood: "Steady", factor: "Other", note: "End"),
                CheckIn(date: end, mood: "Mixed", factor: "Other", note: "Next day")
            ]
            XCTAssertEqual(MoodCalendar.entries(entries, on: start, calendar: calendar).map(\.note), ["Start", "End"])
            XCTAssertEqual(MoodCalendar.entries(entries, in: DateInterval(start: start, end: end)).map(\.note), ["Start", "End"])
        }
    }
    @MainActor func testBackdatedMultipleMoodsEditingAndPersistence() throws {
        let file = temporaryFile()
        let store = WildStore(file: file)
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        store.checkIn(mood: "Low", factor: "Work", note: "Morning", date: date)
        let first = try XCTUnwrap(store.state.checkIns.first)
        store.checkIn(mood: "Steady", factor: "Other", note: "Later", date: date.addingTimeInterval(60))
        store.checkIn(mood: "Mixed", factor: "Study", note: "Edited", date: date, editingID: first.id)
        XCTAssertEqual(store.state.checkIns.count, 2)
        XCTAssertEqual(store.state.checkIns.last?.mood, "Mixed")
        XCTAssertEqual(store.state.checkIns.last?.id, first.id)
        XCTAssertEqual(store.state.discoveries.count, 0)
        store.checkIn(mood: "Bright", factor: "Other", note: "Future", date: Date().addingTimeInterval(86_400))
        XCTAssertEqual(store.state.checkIns.count, 2)
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.state.checkIns.last?.note, "Edited")
        XCTAssertFalse(reopened.progressExport.contains("Edited"))
        XCTAssertTrue(reopened.privateExport.contains("Edited"))
    }

    @MainActor func testDailyCheckInPromptRewardAndRollover() throws {
        let file = temporaryFile()
        let draw: (Int) -> RewardDraw = { count in
            XCTAssertEqual(count, Catalog.allSpecies.count)
            return RewardDraw(speciesIndex: count - 1, rarityRoll: 95)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Australia/Sydney"))
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: now))
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: now))
        let store = WildStore(file: file, drawReward: draw)
        XCTAssertTrue(store.shouldOfferDailyCheckIn(at: now, calendar: calendar))
        let reopened = WildStore(file: file, drawReward: draw)
        XCTAssertFalse(reopened.shouldOfferDailyCheckIn(at: now, calendar: calendar))
        XCTAssertNil(reopened.checkIn(mood: "Low", factor: "Other", note: "", date: yesterday, now: now, calendar: calendar))
        let oldEntry = try XCTUnwrap(reopened.state.checkIns.first)
        XCTAssertNil(reopened.checkIn(mood: "Low", factor: "Other", note: "", date: now, editingID: oldEntry.id, now: now, calendar: calendar))
        let reward = try XCTUnwrap(reopened.checkIn(mood: "Low", factor: "Other", note: "", date: now, now: now, calendar: calendar))
        XCTAssertEqual(reward.speciesID, Catalog.allSpecies.last?.id)
        XCTAssertEqual(reward.rarity, .myth)
        let saved = WildStore(file: file, drawReward: draw)
        XCTAssertEqual(saved.pendingRewards, [reward])
        XCTAssertNil(saved.checkIn(mood: "Bright", factor: "Other", note: "", date: now, now: now, calendar: calendar))
        XCTAssertTrue(saved.shouldOfferDailyCheckIn(at: tomorrow, calendar: calendar))
        XCTAssertNotNil(saved.checkIn(mood: "Mixed", factor: "Other", note: "", date: tomorrow, now: tomorrow, calendar: calendar))
        XCTAssertEqual(saved.rewards.count, 2)
    }

    func testCardSizesAreSpeciesBoundedAndStableAcrossDecoding() throws {
        for species in Catalog.allSpecies {
            let first = AnimalReward(id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                                     speciesID: species.id, rarity: .rare, date: Date(), practiceID: nil)
            let second = AnimalReward(id: UUID(uuid: (0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)),
                                      speciesID: species.id, rarity: .rare, date: Date(), practiceID: nil)
            let size = first.sizeInMillimetres(for: species)
            XCTAssertTrue(species.cardMeasurement.range.contains(size))
            XCTAssertNotEqual(size, second.sizeInMillimetres(for: species))
            let restored = try JSONDecoder().decode(AnimalReward.self, from: JSONEncoder().encode(first))
            XCTAssertEqual(restored.sizeInMillimetres(for: species), size)
        }
    }

    func testRarityOddsAndBoundaries() {
        let results = (0..<100).map(CharacterRarity.rolled)
        XCTAssertEqual(results.filter { $0 == .rare }.count, 70)
        XCTAssertEqual(results.filter { $0 == .epic }.count, 25)
        XCTAssertEqual(results.filter { $0 == .myth }.count, 5)
        XCTAssertEqual(CharacterRarity.rolled(69), .rare)
        XCTAssertEqual(CharacterRarity.rolled(70), .epic)
        XCTAssertEqual(CharacterRarity.rolled(94), .epic)
        XCTAssertEqual(CharacterRarity.rolled(95), .myth)
    }
    @MainActor func testOldDiscoveriesMigrateExactlyOnceAndKeepPendingArrivals() throws {
        let file = temporaryFile()
        var old = SavedState()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        old.discoveries = ["panda": date, "otter": date]
        old.pendingSpecies = "panda"; old.pendingQueue = ["otter"]
        old.checkIns = [CheckIn(mood: "Low", factor: "Study", note: "Keep me")]
        try JSONEncoder().encode(old).write(to: file)
        let store = WildStore(file: file)
        XCTAssertEqual(store.rewards.count, 2)
        XCTAssertTrue(store.rewards.allSatisfy { $0.rarity == .rare && $0.date == date })
        XCTAssertEqual(store.pendingRewards.map(\.speciesID), ["panda", "otter"])
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.rewards.map(\.id), store.rewards.map(\.id))
        XCTAssertEqual(reopened.state.checkIns.first?.note, "Keep me")
    }
    @MainActor func testTimerCompletionAndGentlerManualCompletionUseSameRewardRules() throws {
        let file = temporaryFile()
        let world = Catalog.worlds[0]
        var saved = SavedState()
        saved.learned = [world.id]
        saved.session = WalkSession(worldID: world.id, target: 60, startedAt: Date().addingTimeInterval(-61))
        try JSONEncoder().encode(saved).write(to: file)
        let store = WildStore(file: file, drawReward: { _ in RewardDraw(speciesIndex: 1, rarityRoll: 98) })
        XCTAssertNotNil(store.complete(world, manual: false))
        store.begin(world, minutes: 10, gentler: true)
        XCTAssertNotNil(store.complete(world, manual: true))
        XCTAssertEqual(store.rewards.map(\.rarity), [.myth, .myth])
        XCTAssertEqual(store.rewards.map(\.speciesID), [world.speciesPool[1].id, world.speciesPool[1].id])
    }
    @MainActor func testLessonDraftResumeValidationAndPlanPersistence() {
        let file = temporaryFile()
        let store = WildStore(file: file)
        let world = Catalog.worlds[0]
        store.setMinutes(1); store.setGentler(true)
        let draft = LessonDraft(step: 3, optionID: "forest-2", answer: 0)
        store.saveLessonDraft(draft, for: world)
        let reopened = WildStore(file: file)
        XCTAssertEqual(reopened.lessonDraft(for: world), draft)
        XCTAssertEqual(reopened.preferences.minutes, 1)
        XCTAssertTrue(reopened.preferences.gentler)
        XCTAssertFalse(reopened.state.learned.contains(world.id))
        reopened.saveLessonDraft(LessonDraft(step: 4, optionID: "forest-2", answer: world.correct), for: world)
        XCTAssertEqual(reopened.lessonDraft(for: world).step, 3)
        reopened.saveLessonDraft(LessonDraft(step: 2, optionID: "ocean-1"), for: world)
        XCTAssertEqual(reopened.lessonDraft(for: world), draft)
        reopened.learn(world.id)
        reopened.saveLessonDraft(LessonDraft(step: 4, optionID: "forest-2", answer: world.correct), for: world)
        XCTAssertEqual(WildStore(file: file).lessonDraft(for: world).step, 4)
        XCTAssertTrue(reopened.rewards.isEmpty)
    }
    func testRarityRevealsHaveDifferentTapAndParticleCounts() {
        XCTAssertEqual(CharacterRarity.allCases.map(\.revealTaps), [1, 2, 3])
        XCTAssertEqual(CharacterRarity.allCases.map(\.starCount), [6, 12, 18])
    }
    @MainActor func testEarlierCrossWorldCharactersArePreserved() throws {
        let file = temporaryFile()
        var state = SavedState()
        let old = AnimalReward(speciesID: "otter", rarity: .myth, date: Date(), practiceID: UUID())
        state.rewards = [old]; state.pendingRewardIDs = [old.id]
        try JSONEncoder().encode(state).write(to: file)
        let store = WildStore(file: file)
        XCTAssertEqual(store.rewards.first?.id, old.id)
        XCTAssertEqual(store.rewards.first?.rarity, .myth)
        XCTAssertEqual(store.pendingRewards.first?.speciesID, "otter")
    }
    private func temporaryFile() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent("wildwell-test-\(UUID()).json") }
}
