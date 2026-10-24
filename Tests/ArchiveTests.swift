import XCTest
@testable import FoldLogCore

final class ArchiveTests: XCTestCase {
    func testPersistenceSeparatesDemoFromDeviceAndRoundTrips() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let repository = ArchiveRepository(directory: directory)
        var demo = RecordArchive(mode: .demo)
        demo.events.append(FoldEvent(kind: .closed, countedAt: Date()))
        try repository.save(demo)
        XCTAssertEqual(try repository.load(.demo).events, demo.events)
        XCTAssertTrue(try repository.load(.device).events.isEmpty)
    }

    func testCorruptFileIsNotSilentlyReplaced() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository = ArchiveRepository(directory: directory)
        let bytes = Data("corrupt-data".utf8)
        try bytes.write(to: repository.url(for: .demo))
        XCTAssertThrowsError(try repository.load(.demo))
        XCTAssertEqual(try Data(contentsOf: repository.url(for: .demo)), bytes)
    }

    func testGoalChangesPreservePastDaysAndClosingCancelsScheduledGoal() {
        var archive = RecordArchive(mode: .demo)
        archive.timezoneIdentifier = "Asia/Shanghai"
        let today = archive.calendar.startOfDay(for: Date())
        let tomorrow = archive.calendar.date(byAdding: .day, value: 1, to: today)!
        let yesterday = archive.calendar.date(byAdding: .day, value: -1, to: today)!
        archive.setLimit(30, for: .closed, from: yesterday)
        archive.setLimit(20, for: .closed, from: tomorrow)
        XCTAssertEqual(archive.limit(for: .closed, on: today), 30)
        XCTAssertEqual(archive.limit(for: .closed, on: tomorrow), 20)
        archive.setLimit(nil, for: .closed, from: today)
        XCTAssertEqual(archive.limit(for: .closed, on: yesterday), 30)
        XCTAssertNil(archive.limit(for: .closed, on: today))
        XCTAssertNil(archive.limit(for: .closed, on: tomorrow))
    }

    func testArchiveRejectsMixedSourceAndDuplicateEvents() {
        var archive = RecordArchive(mode: .demo)
        XCTAssertThrowsError(try archive.validate(expectedMode: .device))
        let event = FoldEvent(kind: .fullyOpen, countedAt: Date())
        archive.events = [event, event]
        XCTAssertThrowsError(try archive.validate(expectedMode: .demo))
    }
}
