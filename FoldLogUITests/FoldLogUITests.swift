import XCTest

final class FoldLogUITests: XCTestCase {
    @MainActor private var app: XCUIApplication!

    @MainActor private func launchApp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-data"]
        app.launch()
    }

    @MainActor func testHalfOpenFlowAndPersistence() {
        launchApp()
        tap("simulate-halfOpen")
        let count = app.staticTexts["hero-count"]
        let confirmed = NSPredicate(format: "label == %@", "1")
        expectation(for: confirmed, evaluatedWith: count)
        waitForExpectations(timeout: 4)
        tap("simulate-fullyOpen")
        XCTAssertEqual(count.label, "1")
        tap("simulate-closed")
        XCTAssertEqual(count.label, "1")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertEqual(app.staticTexts["hero-count"].label, "1")
        XCTAssertTrue(app.staticTexts["累计已记录 1 次"].exists)
    }

    @MainActor func testUnsupportedPhoneCannotEnterApp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--check-device-support"]
        app.launch()
        XCTAssertTrue(app.staticTexts["unsupported-device-title"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["今日"].exists)
        XCTAssertFalse(app.buttons["simulate-closed"].exists)
        capture("unsupported-device")
    }

    @MainActor func testGoalValidationAndHistory() {
        launchApp()
        app.buttons["设置"].tap()
        tap("goal-closed")
        let toggle = app.switches["goal-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        // The native Form can expose the switch either as a row or a nested control.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let input = app.textFields["goal-limit"]
        XCTAssertTrue(input.waitForExistence(timeout: 3))
        input.tap()
        input.typeText("0")
        app.buttons["save-goal"].tap()
        XCTAssertTrue(app.staticTexts["goal-error"].exists)
        input.typeText(XCUIKeyboardKey.delete.rawValue + "3")
        if app.buttons["完成"].isHittable { app.buttons["完成"].tap() }
        capture("goal-editor")
        app.buttons["save-goal"].tap()
        XCTAssertTrue(app.staticTexts["每日上限 3 次"].waitForExistence(timeout: 2))
        capture("settings-with-goal")
        app.buttons["今日"].tap()
        tap("simulate-fullyOpen")
        tap("simulate-closed")
        app.buttons["历史"].tap()
        capture("history-with-records")
        tap("history-today")
        XCTAssertTrue(app.staticTexts["已记录次数"].exists)
        let goal = app.descendants(matching: .any)["day-goal-closed"]
        XCTAssertTrue(goal.waitForExistence(timeout: 3))
        capture("day-detail-with-goal")
        XCTAssertTrue(goal.label.contains("上限 3 次"), goal.debugDescription)
    }

    @MainActor func testModeSeparation() {
        launchApp()
        tap("simulate-fullyOpen")
        tap("simulate-closed")
        app.buttons["设置"].tap()
        selectSettingsCategory("recording")
        tap("input-mode")
        app.buttons["设备记录"].tap()
        app.buttons["今日"].tap()
        XCTAssertEqual(app.staticTexts["hero-count"].label, "0")
        XCTAssertFalse(app.buttons["simulate-closed"].exists)
        app.buttons["设置"].tap()
        selectSettingsCategory("recording")
        tap("input-mode")
        app.buttons["演示模式"].tap()
        app.buttons["今日"].tap()
        XCTAssertEqual(app.staticTexts["hero-count"].label, "1")
    }

    @MainActor func testScreenshotsAndAdaptiveLayout() {
        launchApp()
        capture("today-light")
        app.swipeUp()
        capture("today-goals-light")
        app.buttons["历史"].tap()
        capture("history-light")
        app.buttons["设置"].tap()
        capture("settings-light")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        capture("today-dark")
        app.buttons["历史"].tap()
        capture("history-dark")
        app.buttons["设置"].tap()
        capture("settings-dark")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--large-text", "--dark"]
        app.launch()
        capture("today-dark-largest-text")
        app.swipeUp()
        capture("today-dark-largest-text-scrolled")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        capture("today-landscape")
        app.buttons["历史"].tap()
        capture("history-landscape")
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor func testAccessibleControlsWithLargeText() {
        launchApp()
        app.terminate()
        app.launchArguments = ["--ui-testing", "--large-text"]
        app.launch()
        tap("simulate-fullyOpen")
        tap("simulate-closed")
        app.swipeDown()
        capture("large-text-after-opening")
    }

    @MainActor func testAdaptiveNavigationAndGoalDraft() {
        launchApp()
        app.launchArguments = ["--ui-testing"]
        let settings = app.buttons["设置"].firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 8), app.debugDescription)
        // Duo exposes its vertical tabs as toolbar buttons rather than a bottom TabBar.
        if ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] == "iPhone19,4" {
            let today = app.buttons["今日"].firstMatch.frame
            XCTAssertEqual(settings.frame.midX, today.midX, accuracy: 4)
            XCTAssertGreaterThan(settings.frame.midY, today.midY)
        }
        capture("duo-vertical-today")
        app.open(URL(string: "foldlog://goal/closed")!)
        let toggle = app.switches["goal-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        capture("duo-goal-form-light")
        enableGoal()
        let input = app.textFields["goal-limit"]
        input.tap()
        input.typeText("42")
        capture("duo-goal-form-keyboard")
        if app.buttons["完成"].isHittable { app.buttons["完成"].tap() }
        app.buttons["取消"].firstMatch.tap()
        XCTAssertTrue(app.buttons["放弃修改"].waitForExistence(timeout: 3))
        capture("duo-goal-discard-confirmation")
        app.buttons["放弃修改"].tap()
        XCTAssertFalse(input.waitForExistence(timeout: 1))

        settings.tap()
        selectSettingsCategory("goals")
        tap("goal-closed")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "0")
        enableGoal()
        input.tap()
        input.typeText("42")
        if app.buttons["完成"].isHittable { app.buttons["完成"].tap() }
        app.buttons["save-goal"].tap()
        tap("goal-closed")
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        XCTAssertEqual(input.value as? String, "42")
        app.buttons["取消"].firstMatch.tap()
        app.buttons["历史"].firstMatch.tap()
        capture("duo-vertical-history")
    }

    @MainActor private func enableGoal() {
        let controls = app.switches.matching(identifier: "goal-enabled").allElementsBoundByIndex
            .filter { $0.isHittable }
        guard let control = controls.min(by: { $0.frame.width < $1.frame.width }) else {
            return XCTFail("每日上限开关不可点击")
        }
        // The identifier may belong to the entire Form row, including its trailing inset.
        // A fixed inset reaches the native switch on both compact and wide forms.
        control.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -min(40, control.frame.width / 2), dy: 0)).tap()
        let input = app.textFields["goal-limit"]
        let enabled = NSPredicate(format: "enabled == true")
        expectation(for: enabled, evaluatedWith: input)
        waitForExpectations(timeout: 4)
    }

    @MainActor func testSettingsSplitLayoutAndRotation() {
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        launchApp()
        app.buttons["设置"].tap()
        let goalsCategory = app.descendants(matching: .any)["settings-category-goals"].firstMatch
        XCTAssertTrue(goalsCategory.waitForExistence(timeout: 5))
        let goal = app.buttons["goal-closed"]
        XCTAssertTrue(goal.isHittable)
        capture("duo-settings-split-light")
        XCTAssertGreaterThan(goal.frame.minX, goalsCategory.frame.maxX)
        // Duo's application accessibility frame can retain portrait dimensions after rotation.
        XCTAssertLessThan(goal.frame.width, max(app.frame.width, app.frame.height) * 0.75)
        let title = app.staticTexts["设置"].firstMatch
        let tab = app.buttons["设置"]
        XCTAssertFalse(title.frame.intersects(tab.frame), "导航不能遮住页面标题")

        selectSettingsCategory("recording")
        XCTAssertTrue(app.buttons["input-mode"].isHittable)
        XCTAssertFalse(goal.exists)
        selectSettingsCategory("data")
        XCTAssertTrue(app.buttons["clear-records"].isHittable)
        selectSettingsCategory("about")
        app.buttons["计数规则与记录范围"].tap()
        XCTAssertTrue(app.navigationBars["计数与记录范围"].waitForExistence(timeout: 3))
        // Selecting another category also resets its native detail navigation stack.
        selectSettingsCategory("goals")
        tap("goal-closed")
        XCTAssertTrue(app.switches["goal-enabled"].waitForExistence(timeout: 3))
        app.buttons["取消"].tap()

        XCUIDevice.shared.orientation = .portrait
        // The Duo runtime can keep its inner display wide after a device rotation.
        // Follow the available space rather than assuming portrait means compact.
        XCTAssertTrue(goal.exists)
        if goalsCategory.exists {
            XCTAssertGreaterThan(goal.frame.minX, goalsCategory.frame.maxX)
        } else {
            XCTAssertTrue(app.buttons["input-mode"].waitForExistence(timeout: 5))
        }
        capture("duo-settings-rotated")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(goalsCategory.waitForExistence(timeout: 5))
        XCTAssertTrue(goal.isHittable)

        app.terminate()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        app.buttons["设置"].tap()
        capture("duo-settings-split-dark")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--large-text"]
        app.launch()
        app.buttons["设置"].tap()
        XCTAssertFalse(goalsCategory.exists)
        XCTAssertTrue(app.buttons["input-mode"].waitForExistence(timeout: 5))
        capture("duo-settings-largest-text")
        let form = app.descendants(matching: .any)["settings-detail-all"].firstMatch
        form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            .press(forDuration: 0.05, thenDragTo: form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55)))
        capture("duo-settings-largest-text-scrolled")
        let largeGoal = app.buttons["goal-closed"]
        XCTAssertTrue(largeGoal.isHittable)
        // Use the visible leading area when a tall row extends below the tab bar.
        largeGoal.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.2)).tap()
        XCTAssertTrue(app.navigationBars["折叠目标"].waitForExistence(timeout: 3))
        let goalSwitch = app.switches["goal-enabled"]
        for _ in 0..<4 {
            if goalSwitch.exists && goalSwitch.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(goalSwitch.isHittable)
        capture("duo-goal-editor-largest-text")
    }

    @MainActor private func selectSettingsCategory(_ name: String) {
        let category = app.descendants(matching: .any)["settings-category-\(name)"].firstMatch
        if category.exists { category.tap() }
    }

    @MainActor private func tap(_ identifier: String) {
        let element = app.buttons[identifier]
        for _ in 0..<4 {
            if element.isHittable { element.tap(); return }
            app.swipeUp()
        }
        XCTFail("Control not reachable: \(identifier)")
    }

    @MainActor private func capture(_ name: String) {
        FileHandle.standardOutput.write(Data("FOLDLOG_SCREENSHOT: \(name)\n".utf8))
        // Device rotation and native tab transitions can outlast the accessibility update.
        Thread.sleep(forTimeInterval: 1)
        // Duo's main screen can be the inactive outer display. Prefer its additional screen.
        // Other phones need the full screen to avoid stale portrait crop bounds.
        let isDuo = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] == "iPhone19,4"
        let screen = isDuo ? XCUIScreen.screens.last ?? XCUIScreen.main : XCUIScreen.main
        let attachment = XCTAttachment(screenshot: screen.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
