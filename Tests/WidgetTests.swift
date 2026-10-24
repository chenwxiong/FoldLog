import XCTest
@testable import FoldLogCore

final class WidgetTests: XCTestCase {
    private let now = ISO8601DateFormatter().date(from: "2026-10-24T12:00:00+08:00")!

    private func archive(count: Int = 3, limit: Int? = 10, mode: InputMode = .device) -> RecordArchive {
        var archive = RecordArchive(mode: mode)
        archive.timezoneIdentifier = "Asia/Shanghai"
        archive.events = (0..<count).map { _ in FoldEvent(kind: .closed, countedAt: now) }
        archive.setLimit(limit, for: .closed, from: now)
        return archive
    }

    func testOnlyTodayClosedEventsBecomeWidgetFolds() {
        var archive = archive()
        archive.events.append(FoldEvent(kind: .halfOpen, countedAt: now))
        archive.events.append(FoldEvent(kind: .fullyOpen, countedAt: now))
        archive.events.append(FoldEvent(kind: .closed, countedAt: now.addingTimeInterval(-86400)))
        let value = WidgetSnapshot(archive: archive, at: now).value(at: now)
        XCTAssertEqual(value.count, 3)
        XCTAssertEqual(value.remaining, 7)
        XCTAssertEqual(value.progress, 0.3, accuracy: 0.001)
        XCTAssertEqual(value.mode, .device)
    }

    func testUnsetReachedAndExceededAreDifferentStates() {
        let unset = WidgetSnapshot(archive: archive(limit: nil), at: now).value(at: now)
        XCTAssertNil(unset.remaining)
        XCTAssertEqual(unset.goalStatus, "未设置目标")
        let reached = WidgetSnapshot(archive: archive(limit: 3), at: now).value(at: now)
        XCTAssertEqual(reached.remaining, 0)
        XCTAssertEqual(reached.goalStatus, "已达上限")
        let exceeded = WidgetSnapshot(archive: archive(count: 13), at: now).value(at: now)
        XCTAssertEqual(exceeded.count, 13)
        XCTAssertEqual(exceeded.remaining, 0)
        XCTAssertEqual(exceeded.exceeded, 3)
        XCTAssertEqual(exceeded.progress, 1)
    }

    func testMidnightRolloverAppliesFutureGoalWithoutOpeningApp() {
        var archive = archive()
        let tomorrow = archive.calendar.date(byAdding: .day, value: 1, to: now)!
        archive.setLimit(20, for: .closed, from: tomorrow)
        let snapshot = WidgetSnapshot(archive: archive, at: now)
        XCTAssertEqual(snapshot.value(at: now).limit, 10)
        let midnight = snapshot.timelineDates(from: now)[1]
        XCTAssertEqual(archive.calendar.component(.hour, from: midnight), 0)
        let value = snapshot.value(at: midnight)
        XCTAssertEqual(value.count, 0)
        XCTAssertEqual(value.limit, 20)
        XCTAssertEqual(value.remaining, 20)
        XCTAssertTrue(value.needsSync)
        XCTAssertEqual(value.status, "今日尚未同步")
    }

    func testTimelineUsesCalendarMidnightsAcrossDST() {
        var archive = archive()
        archive.timezoneIdentifier = "America/Los_Angeles"
        let beforeDST = ISO8601DateFormatter().date(from: "2026-10-31T12:00:00-07:00")!
        let snapshot = WidgetSnapshot(archive: archive, at: beforeDST)
        let dates = snapshot.timelineDates(from: beforeDST)
        XCTAssertEqual(dates.count, 8)
        XCTAssertTrue(dates.dropFirst().allSatisfy { snapshot.calendar.component(.hour, from: $0) == 0 })
        XCTAssertEqual(dates[2].timeIntervalSince(dates[1]), 25 * 3600)
    }

    func testSwitchSourceAndClearReplaceProjectionWithoutChangingArchives() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = WidgetSnapshotRepository(directory: directory)
        let device = archive()
        let archives = ArchiveRepository(directory: directory)
        try archives.save(device)
        let original = try Data(contentsOf: archives.url(for: .device))
        try repository.save(WidgetSnapshot(archive: device, at: now))
        XCTAssertEqual(try repository.load().value(at: now).count, 3)
        try repository.save(WidgetSnapshot(archive: archive(count: 8, mode: .demo), at: now))
        XCTAssertEqual(try repository.load().mode, .demo)
        XCTAssertEqual(try repository.load().value(at: now).count, 8)
        try repository.save(WidgetSnapshot(archive: RecordArchive(mode: .demo), at: now))
        XCTAssertEqual(try repository.load().value(at: now).count, 0)
        XCTAssertNil(try repository.load().value(at: now).limit)
        XCTAssertEqual(try Data(contentsOf: archives.url(for: .device)), original)
    }

    func testUnreadableAndPausedStorageDoNotInventCounts() {
        let unreadable = WidgetSnapshot(archive: archive(), at: now, readable: false, recordingPaused: true)
        XCTAssertNil(unreadable.value(at: now).count)
        XCTAssertNil(unreadable.value(at: now).remaining)
        let paused = WidgetSnapshot(archive: archive(), at: now, recordingPaused: true).value(at: now)
        XCTAssertEqual(paused.count, 3)
        XCTAssertEqual(paused.status, "记录已暂停")
        XCTAssertNil(WidgetValue(date: now).count)
    }

    func testBadProjectionIsRejectedAndBytesPreserved() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = WidgetSnapshotRepository(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let bytes = Data("invalid".utf8)
        try bytes.write(to: repository.url)
        XCTAssertThrowsError(try repository.load())
        XCTAssertEqual(try Data(contentsOf: repository.url), bytes)
        var snapshot = WidgetSnapshot(archive: archive(), at: now)
        snapshot.schemaVersion = 999
        XCTAssertThrowsError(try repository.save(snapshot))
        XCTAssertEqual(try Data(contentsOf: repository.url), bytes)
    }

    func testWidgetLinksOnlyResolveKnownRoutes() {
        XCTAssertEqual(WidgetDestination(url: WidgetDestination.today.url), .today)
        XCTAssertEqual(WidgetDestination(url: WidgetDestination.goal.url), .goal)
        XCTAssertNil(WidgetDestination(url: URL(string: "https://goal/closed")!))
        XCTAssertNil(WidgetDestination(url: URL(string: "foldlog://goal/fullyOpen")!))
    }
}
