import XCTest

final class WidgetUITests: XCTestCase {
    @MainActor private var app: XCUIApplication!

    @MainActor func testWidgetGallerySharingAndDeepLinks() {
        continueAfterFailure = false
        app = XCUIApplication()
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
        openGallery()
        let countPreview = app.otherElements["widget-summary-small-preview"]
        XCTAssertTrue(countPreview.waitForExistence(timeout: 4))
        XCTAssertTrue(countPreview.label.contains("剩余 2 次"), countPreview.label)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "小组件暂未同步")).firstMatch.exists)
        capture("widget-shared-after-save")
        app.segmentedControls.buttons["示例效果"].tap()
        capture("widget-gallery-light")
        scrollGallery()
        capture("widget-lock-styles")

        app.open(URL(string: "foldlog://today")!)
        XCTAssertTrue(app.buttons["simulate-closed"].waitForExistence(timeout: 4))
        XCTAssertEqual(app.staticTexts["hero-count"].label, "1")
        app.buttons["设置"].tap()
        category("recording")
        app.buttons["input-mode"].tap()
        app.buttons["设备记录"].tap()
        capture("widget-shared-device-source")
        app.buttons["input-mode"].tap()
        app.buttons["演示模式"].tap()
        category("data")
        reveal(app.buttons["clear-records"])
        app.buttons["clear-records"].tap()
        app.buttons["清空数据"].tap()
        capture("widget-shared-cleared")

        app.terminate()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        openGallery()
        app.segmentedControls.buttons["示例效果"].tap()
        capture("widget-gallery-dark")
    }

    @MainActor func testWidgetGalleryWithLargestText() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--large-text"]
        app.launch()
        openGallery()
        XCTAssertTrue(app.segmentedControls.buttons["当前记录"].exists)
        capture("widget-gallery-largest-text")
        scrollGallery()
        capture("widget-gallery-largest-text-scrolled")
    }

    @MainActor func testWidgetStylesInLightAndDark() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        openGallery()
        app.segmentedControls.buttons["示例效果"].tap()
        capture("widget-minimal-light")
        scrollGallery()
        capture("widget-minimal-lock-light")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        openGallery()
        app.segmentedControls.buttons["示例效果"].tap()
        capture("widget-minimal-dark")
        scrollGallery()
        capture("widget-minimal-lock-dark")
    }

    @MainActor func testCombinedWidgetStates() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        openGallery()
        app.segmentedControls.buttons["示例效果"].tap()
        let preview = app.otherElements["widget-summary-small-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 4))
        XCTAssertTrue(preview.label.contains("折叠 24 次"), preview.label)
        XCTAssertTrue(preview.label.contains("剩余 36 次"), preview.label)
        XCTAssertFalse(app.otherElements["widget-remaining-small-preview"].exists)
        capture("widget-combined-light")

        let states: [(String, [String], String)] = [
            ("未设目标", ["折叠 24 次", "未设置每日上限"], "unset"),
            ("达到上限", ["折叠 60 次", "剩余 0 次", "已达上限"], "reached"),
            ("超出上限", ["折叠 63 次", "剩余 0 次", "已超出 3 次"], "exceeded"),
            ("大数字", ["折叠 123456 次", "剩余 876543 次"], "large"),
            ("待同步", ["记录暂不可用"], "unavailable")
        ]
        for (title, labels, name) in states {
            app.buttons["widget-preview-state"].tap()
            app.buttons[title].tap()
            for label in labels { XCTAssertTrue(preview.label.contains(label), preview.label) }
            capture("widget-combined-\(name)")
            if name == "large" {
                scrollGallery()
                let circular = app.otherElements["widget-summary-circular-preview"]
                XCTAssertTrue(circular.label.contains("折叠 123456 次"), circular.label)
                XCTAssertTrue(circular.label.contains("剩余 876543 次"), circular.label)
                capture("widget-combined-lock-large")
                app.scrollViews["widget-gallery-scroll"].swipeDown()
            }
        }
        app.buttons["widget-preview-state"].tap()
        app.buttons["目标内"].tap()
        scrollGallery()
        let circular = app.otherElements["widget-summary-circular-preview"]
        XCTAssertTrue(circular.exists)
        XCTAssertTrue(circular.label.contains("剩余 36 次"), circular.label)
        capture("widget-combined-lock-light")

        app.terminate()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        openGallery()
        app.segmentedControls.buttons["示例效果"].tap()
        capture("widget-combined-dark")
        scrollGallery()
        capture("widget-combined-lock-dark")
    }

    @MainActor private func openGallery() {
        app.buttons["设置"].tap()
        category("widgets")
        let link = app.buttons["widget-gallery"]
        reveal(link)
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        link.tap()
    }

    @MainActor private func reveal(_ element: XCUIElement) {
        for _ in 0..<10 {
            if element.isHittable { break }
            let form = app.descendants(matching: .any)["settings-detail-all"].firstMatch
            if form.exists {
                form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                    .press(forDuration: 0.05, thenDragTo: form.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
            } else { app.swipeUp() }
        }
    }

    @MainActor private func category(_ value: String) {
        let row = app.descendants(matching: .any)["settings-category-\(value)"].firstMatch
        if row.waitForExistence(timeout: 1) { row.tap() }
    }

    @MainActor private func scrollGallery() {
        let scroll = app.scrollViews["widget-gallery-scroll"]
        scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.75))
            .press(forDuration: 0.05,
                   thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.35)),
                   withVelocity: .slow, thenHoldForDuration: 0.2)
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
