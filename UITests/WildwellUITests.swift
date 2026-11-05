import XCTest

final class WildwellUITests: XCTestCase {
    @MainActor func testAutomaticRandomRewardsRepeatsAndMinimalHome() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["WILDWELL_SKIP_DAILY_PROMPT"] = "1"
        app.launch()
        scrollTo(app.buttons["Let’s explore"], in: app); app.buttons["Let’s explore"].tap()
        XCTAssertTrue(app.staticTexts["What would help right now?"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["collection.totals"].exists)
        scrollTo(app.buttons["Move a little"], in: app); app.buttons["Move a little"].tap()
        attach(app, "Minimal home")
        let forest = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Cloud Forest")).firstMatch
        scrollTo(forest, in: app); forest.tap()
        scrollTo(app.buttons["Open bite-size lesson"], in: app); app.buttons["Open bite-size lesson"].tap()
        app.buttons["Continue"].tap()
        let example = app.buttons["lesson.example.forest-2"]
        scrollTo(example, in: app); example.tap()
        attach(app, "Interactive lesson")
        app.terminate(); app.launch()
        scrollTo(forest, in: app); forest.tap()
        scrollTo(app.buttons["Resume guide"], in: app); app.buttons["Resume guide"].tap()
        XCTAssertTrue(app.staticTexts["What fits your real day?"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()
        XCTAssertEqual(app.staticTexts["lesson.plannedPractice"].label, "Uncurl from your desk")
        app.segmentedControls.buttons["1 min"].tap()
        app.switches["Use the gentler version"].tap()
        attach(app, "Learning practice plan")
        app.buttons["Continue"].tap()
        scrollTo(app.buttons["Pushing through discomfort"], in: app); app.buttons["Pushing through discomfort"].tap()
        XCTAssertFalse(app.buttons["Choose an answer above"].isEnabled)
        scrollTo(app.buttons["Choosing movement that fits your body"], in: app); app.buttons["Choosing movement that fits your body"].tap()
        app.buttons["Finish lesson"].tap()
        XCTAssertTrue(app.staticTexts["Guide completed"].waitForExistence(timeout: 5))
        scrollTo(app.buttons["Put it into practice"], in: app); app.buttons["Put it into practice"].tap()
        XCTAssertTrue(app.staticTexts["practice.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["practice.title"].label, "Uncurl from your desk")
        let first = completePractice(app, useTimer: true)
        app.tabBars.buttons["Practise"].tap()
        scrollTo(app.buttons["Choose this practice"].firstMatch, in: app); app.buttons["Choose this practice"].firstMatch.tap()
        let repeatChoice = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Uncurl from your desk")).firstMatch
        scrollTo(repeatChoice, in: app); repeatChoice.tap()
        _ = completePractice(app, useTimer: false)
        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.staticTexts["collection.totals"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["collection.totals"].label.hasPrefix("2 characters"))
        attach(app, "Rarity collection")
        let search = app.textFields["Search characters"]
        scrollTo(search, in: app); search.tap(); search.typeText(first)
        if app.keyboards.buttons["Search"].exists { app.keyboards.buttons["Search"].tap() }
        let character = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "character.")).firstMatch
        XCTAssertTrue(character.waitForExistence(timeout: 5)); character.tap()
        scrollTo(app.buttons["About this real species"], in: app)
        XCTAssertTrue(app.buttons["About this real species"].exists)
        attach(app, "Character variants")
        app.terminate(); app.launch(); app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.staticTexts["collection.totals"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["collection.totals"].label.hasPrefix("2 characters"))
    }
    @MainActor func testEachRarityTapSequenceAndAnimationBypass() {
        continueAfterFailure = false
        for (rarity, requiredTaps) in [("rare", 1), ("epic", 2), ("myth", 3)] {
            let app = XCUIApplication()
            app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
            app.launchEnvironment["WILDWELL_SKIP_DAILY_PROMPT"] = "1"
            app.launchEnvironment["WILDWELL_TEST_REVEAL"] = rarity
            app.launch()
            app.tabBars.buttons["Practise"].tap()
            scrollTo(app.buttons["Choose this practice"].firstMatch, in: app); app.buttons["Choose this practice"].firstMatch.tap()
            scrollTo(app.buttons["Prepare my practice"], in: app); app.buttons["Prepare my practice"].tap()
            scrollTo(app.buttons["I completed it without the timer"], in: app); app.buttons["I completed it without the timer"].tap()
            app.buttons["Yes, record my practice"].tap()
            XCTAssertTrue(app.buttons["reward.open"].waitForExistence(timeout: 5))
            attach(app, rarity + " sealed reveal")
            for tap in 1...requiredTaps {
                app.buttons["reward.open"].tap()
                if tap < requiredTaps { XCTAssertFalse(app.staticTexts["reward.species"].exists) }
            }
            XCTAssertTrue(app.staticTexts["reward.species"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["reward.species"].label, "Red panda")
            attach(app, rarity + " opened reveal")
            app.terminate()
        }
        let app = XCUIApplication()
        app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["WILDWELL_SKIP_DAILY_PROMPT"] = "1"
        app.launchEnvironment["WILDWELL_TEST_REVEAL"] = "myth"
        app.launch(); app.tabBars.buttons["Practise"].tap()
        scrollTo(app.buttons["Choose this practice"].firstMatch, in: app); app.buttons["Choose this practice"].firstMatch.tap()
        scrollTo(app.buttons["Prepare my practice"], in: app); app.buttons["Prepare my practice"].tap()
        scrollTo(app.buttons["I completed it without the timer"], in: app); app.buttons["I completed it without the timer"].tap()
        app.buttons["Yes, record my practice"].tap()
        scrollTo(app.buttons["reward.skipAnimation"], in: app); app.buttons["reward.skipAnimation"].tap()
        XCTAssertTrue(app.staticTexts["reward.species"].waitForExistence(timeout: 5))
    }
    @MainActor func testMoodCalendarLoggingEditingAndWeekChart() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["WILDWELL_SKIP_DAILY_PROMPT"] = "1"
        app.launch()
        scrollTo(app.buttons["Let’s explore"], in: app); app.buttons["Let’s explore"].tap()
        app.tabBars.buttons["Mood"].tap()
        XCTAssertTrue(app.buttons["calendar.previous"].waitForExistence(timeout: 5))
        logMood("Steady", app: app)
        logMood("Unsettled", app: app)
        scrollToTop(app.buttons["calendar.today"], in: app)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: yesterday)
        if Calendar.current.component(.month, from: yesterday) != Calendar.current.component(.month, from: Date()) { app.buttons["calendar.previous"].tap() }
        let day = app.buttons["mood.day.\(parts.year!)-\(parts.month!)-\(parts.day!)"]
        scrollTo(day, in: app); day.tap()
        logMood("Low", app: app)
        scrollTo(app.buttons["Edit Low entry"], in: app); app.buttons["Edit Low entry"].tap()
        scrollTo(app.buttons["Mixed"], in: app); app.buttons["Mixed"].tap()
        scrollTo(app.buttons["Save check-in"], in: app); app.buttons["Save check-in"].tap()
        XCTAssertTrue(app.buttons["Edit Mixed entry"].waitForExistence(timeout: 5))
        scrollToTop(app.buttons["calendar.today"], in: app)
        attach(app, "Mood month calendar")
        app.segmentedControls.buttons["Week"].tap()
        scrollTo(app.staticTexts["Feelings through the week"], in: app)
        XCTAssertTrue(app.descendants(matching: .any)["mood.weekChart"].exists)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.48)))
        attach(app, "Mood weekly chart")
        app.terminate(); app.launch(); app.tabBars.buttons["Mood"].tap()
        scrollTo(app.buttons["Edit Steady entry"], in: app)
        XCTAssertTrue(app.buttons["Edit Steady entry"].exists)
        XCTAssertTrue(app.buttons["Edit Unsettled entry"].exists)
        scrollToTop(app.buttons["calendar.previous"], in: app)
        app.buttons["calendar.previous"].tap()
        XCTAssertTrue(app.buttons["calendar.next"].isEnabled)
        app.buttons["calendar.next"].tap()
        XCTAssertFalse(app.buttons["calendar.next"].isEnabled)
    }
    @MainActor func testDailyRewardAndCardShare() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["WILDWELL_TEST_REVEAL"] = "rare"
        app.launch()
        XCTAssertTrue(app.buttons["Skip today"].waitForExistence(timeout: 5))
        app.buttons["Steady"].tap()
        scrollTo(app.buttons["Save check-in"], in: app); app.buttons["Save check-in"].tap()
        scrollTo(app.buttons["reward.skipAnimation"], in: app); app.buttons["reward.skipAnimation"].tap()
        XCTAssertTrue(app.staticTexts["reward.species"].waitForExistence(timeout: 5))
        let share = app.descendants(matching: .any).matching(identifier: "card.share").firstMatch
        XCTAssertTrue(share.waitForExistence(timeout: 5), app.debugDescription)
        scrollTo(share, in: app); share.tap()
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.cells["Assign to Contact"].exists, app.debugDescription)
        app.terminate(); app.launch()
        XCTAssertTrue(app.tabBars.buttons["Collection"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip today"].exists)
        app.tabBars.buttons["Collection"].tap()
        let guide = app.buttons["guide.world.forest"]
        scrollTo(guide, in: app); guide.tap()
        XCTAssertTrue(app.navigationBars["Cloud Forest"].waitForExistence(timeout: 5), app.debugDescription)
        let character = app.buttons["guide.card.panda-rare"]
        scrollTo(character, in: app); character.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "card.share").firstMatch.waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor func testTodayQuickPracticeCheckInRecapAndFieldGuide() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchEnvironment["WILDWELL_TEST_ID"] = UUID().uuidString
        app.launchEnvironment["WILDWELL_SKIP_DAILY_PROMPT"] = "1"
        app.launch()
        scrollTo(app.buttons["Let’s explore"], in: app); app.buttons["Let’s explore"].tap()
        app.segmentedControls["today.duration"].buttons["1 min"].tap()
        let quick = app.buttons["today.tryPractice"]
        scrollTo(quick, in: app); quick.tap()
        XCTAssertEqual(app.staticTexts["practice.title"].label, "Notice five small details")
        XCTAssertTrue(app.staticTexts["1-minute practice"].exists)
        let animal = completePractice(app, useTimer: false, allowed: ["Sea otter", "Green sea turtle", "Bat ray"])

        let checkIn = app.buttons["today.checkIn"]
        scrollToTop(checkIn, in: app); checkIn.tap()
        XCTAssertFalse(app.textViews["Optional note, just for you"].exists)
        app.buttons["Steady"].tap()
        app.buttons["Add a detail"].tap()
        let factor = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Nothing in particular")).firstMatch
        scrollTo(factor, in: app); factor.tap()
        app.buttons["Sleep"].tap()
        app.buttons["Save check-in"].tap()
        scrollTo(app.buttons["reward.skipAnimation"], in: app); app.buttons["reward.skipAnimation"].tap()
        scrollTo(app.buttons["Continue"], in: app); app.buttons["Continue"].tap()

        app.tabBars.buttons["Mood"].tap()
        app.segmentedControls.buttons["Week"].tap()
        let sleep = app.buttons["recap.factor.Sleep"]
        scrollTo(sleep, in: app); attach(app, "Weekly recap"); sleep.tap()
        XCTAssertTrue(app.staticTexts["Steady"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Collection"].tap()
        let guide = app.buttons["guide.world.ocean"]
        scrollTo(guide, in: app); guide.tap()
        XCTAssertTrue(app.navigationBars["Quiet Coast"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(app.staticTexts[animal].exists)
        attach(app, "Quiet Coast field guide")
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "guide.card.")).firstMatch
        scrollTo(card, in: app); card.tap()
        scrollTo(app.staticTexts["card.wildlifeFact"], in: app)
        XCTAssertTrue(app.staticTexts["card.wildlifeFact"].exists)
    }

    @MainActor private func logMood(_ mood: String, app: XCUIApplication) {
        let add = app.buttons.matching(NSPredicate(format: "label IN %@", ["Log a feeling", "Add another moment"])).firstMatch
        scrollTo(add, in: app); add.tap()
        scrollTo(app.buttons[mood], in: app); app.buttons[mood].tap()
        scrollTo(app.buttons["Save check-in"], in: app); app.buttons["Save check-in"].tap()
        let bypass = app.buttons["reward.skipAnimation"]
        if bypass.waitForExistence(timeout: 2) {
            scrollTo(bypass, in: app); bypass.tap()
            scrollTo(app.buttons["Continue"], in: app); app.buttons["Continue"].tap()
        }
    }
    @MainActor private func scrollToTop(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 { if element.exists && element.isHittable { return }; app.swipeDown() }
        XCTFail("Could not scroll back to \(element)")
    }

    @MainActor @discardableResult private func completePractice(_ app: XCUIApplication, useTimer: Bool, allowed: [String] = ["Red panda", "Linnaeus’s two-toed sloth", "Ring-tailed lemur"]) -> String {
        scrollTo(app.buttons["Prepare my practice"], in: app); app.buttons["Prepare my practice"].tap()
        if useTimer {
            scrollTo(app.buttons["Start / resume timer"], in: app); app.buttons["Start / resume timer"].tap()
            XCTAssertTrue(app.buttons["Pause timer"].waitForExistence(timeout: 3)); app.buttons["Pause timer"].tap()
        }
        scrollTo(app.buttons["I completed it without the timer"], in: app); app.buttons["I completed it without the timer"].tap()
        app.buttons["Yes, record my practice"].tap()
        XCTAssertTrue(app.buttons["reward.open"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["reward.species"].exists)
        for _ in 0..<3 {
            if app.staticTexts["reward.species"].exists { break }
            app.buttons["reward.open"].tap()
        }
        XCTAssertTrue(app.staticTexts["reward.species"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Already saved to your collection"].exists)
        let animal = app.staticTexts["reward.species"].label
        XCTAssertTrue(allowed.contains(animal))
        attach(app, "Automatic character reward")
        scrollTo(app.buttons["Continue"], in: app); app.buttons["Continue"].tap()
        scrollTo(app.buttons["Skip for now"], in: app); app.buttons["Skip for now"].tap()
        return animal
    }
    @MainActor private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 { if element.exists && element.isHittable { return }; app.swipeUp() }
        XCTFail("Could not reach \(element)")
    }
    @MainActor private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
