import XCTest

/// Run explicitly: this test changes the simulator's Home Screen layout.
final class SystemWidgetTests: XCTestCase {
    @MainActor func testHomeWidgetDisplaysSharedRecordAndOpensToday() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-data", "--widget-integration-testing"]
        app.launch()
        app.launchArguments = ["--ui-testing", "--widget-integration-testing"]
        app.buttons["simulate-fullyOpen"].tap()
        app.buttons["simulate-closed"].tap()
        app.open(URL(string: "foldlog://goal/closed")!)
        let toggle = app.switches["goal-enabled"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            .withOffset(CGVector(dx: -40, dy: 0)).tap()
        let input = app.textFields["goal-limit"]
        input.tap()
        input.typeText("3")
        if app.buttons["完成"].isHittable { app.buttons["完成"].tap() }
        app.buttons["save-goal"].tap()
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 1)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let widget = springboard.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "剩余折叠", "今日已记录折叠")).firstMatch
        if widget.exists && widget.frame.width > widget.frame.height * 1.4 {
            widget.press(forDuration: 1.5)
            let small = springboard.buttons["小型小组件"]
            XCTAssertTrue(small.waitForExistence(timeout: 5))
            small.tap()
            if springboard.buttons["完成"].exists { springboard.buttons["完成"].tap() }
        } else if !widget.exists {
            var visibleIcon: XCUIElement?
            for _ in 0..<3 {
                visibleIcon = springboard.icons.matching(identifier: "折记").allElementsBoundByIndex.first { $0.isHittable }
                if visibleIcon != nil { break }
                springboard.swipeLeft()
            }
            // Paging can reveal an existing widget; only open the icon menu if it is still absent.
            if !widget.exists {
                let icon = try XCTUnwrap(visibleIcon)
                icon.press(forDuration: 1.5)
                // An app left only in App Library has no widget size controls until added to Home.
                let addToHome = springboard.buttons["添加到主屏幕"]
                if addToHome.exists {
                    addToHome.tap()
                    let homeIcon = try XCTUnwrap(springboard.icons.matching(identifier: "折记")
                        .allElementsBoundByIndex.first { $0.isHittable })
                    homeIcon.press(forDuration: 1.5)
                }
                capture("widget-icon-menu")
                let small = springboard.buttons["小型小组件"]
                XCTAssertTrue(small.waitForExistence(timeout: 5), springboard.debugDescription)
                small.tap()
                if springboard.buttons["完成"].exists { springboard.buttons["完成"].tap() }
            }
        }
        if springboard.buttons["编辑主屏幕"].exists { XCUIDevice.shared.press(.home) }
        XCTAssertTrue(widget.waitForExistence(timeout: 25), springboard.debugDescription)
        let sharedRecord = NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "折叠 1 次", "剩余 2 次")
        expectation(for: sharedRecord, evaluatedWith: widget)
        waitForExpectations(timeout: 25)
        XCTAssertLessThan(widget.frame.width, widget.frame.height * 1.4)
        capture("widget-summary-home-system")
        widget.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).tap()
        XCTAssertTrue(app.navigationBars["今日"].waitForExistence(timeout: 8))
        XCTAssertEqual(app.staticTexts["hero-count"].label, "1")
    }

    @MainActor private func capture(_ name: String) {
        FileHandle.standardOutput.write(Data("FOLDLOG_SCREENSHOT: \(name)\n".utf8))
        Thread.sleep(forTimeInterval: 1)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
