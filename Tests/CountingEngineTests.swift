import XCTest
@testable import FoldLogCore

final class CountingEngineTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    func testConfirmedExamples() {
        let scenarios: [([(FoldPose?, Double)], [Int])] = [
            ([(.closed, 0), (.halfOpen, 1), (.fullyOpen, 1.8), (.closed, 2)], [1, 0, 1]),
            ([(.closed, 0), (.halfOpen, 1), (.fullyOpen, 2), (.closed, 3)], [1, 1, 1]),
            ([(.closed, 0), (.halfOpen, 1), (.closed, 2.5)], [1, 1, 0]),
            ([(.closed, 0), (.halfOpen, 1), (.closed, 1.5)], [1, 0, 0]),
            ([(.closed, 0), (.halfOpen, 1), (.halfOpen, 11)], [0, 1, 0]),
            ([(.closed, 0), (.fullyOpen, 1)], [0, 0, 1]),
            ([(.fullyOpen, 0), (.halfOpen, 1), (.fullyOpen, 3)], [0, 0, 1]),
            ([(.closed, 0), (.halfOpen, 1), (.fullyOpen, 2), (.halfOpen, 3), (.fullyOpen, 4)], [0, 1, 2]),
            ([(.halfOpen, 0), (.halfOpen, 5)], [0, 0, 0]),
            ([(.closed, 0), (.halfOpen, 1), (nil, 1.7), (.halfOpen, 2), (.halfOpen, 2.4)], [0, 0, 0])
        ]
        for (samples, expected) in scenarios {
            var engine = CountingEngine()
            let events = samples.flatMap { engine.observe($0.0, at: $0.1, date: epoch.addingTimeInterval($0.1)) }
            XCTAssertEqual(FoldPose.allCases.map { pose in events.filter { $0.kind == pose }.count }, expected)
        }
    }

    func testTimerAndRepeatedCallbacksConfirmOnlyOnce() {
        var engine = CountingEngine()
        _ = engine.observe(.closed, at: 0, date: epoch)
        _ = engine.observe(.halfOpen, at: 1, date: epoch.addingTimeInterval(1))
        _ = engine.observe(.halfOpen, at: 1.8, date: epoch.addingTimeInterval(1.8))
        XCTAssertTrue(engine.advance(to: 1.999).isEmpty)
        XCTAssertEqual(engine.advance(to: 2).map(\.kind), [.halfOpen])
        XCTAssertTrue(engine.advance(to: 10).isEmpty)
        XCTAssertTrue(engine.observe(.halfOpen, at: 11, date: epoch.addingTimeInterval(11)).isEmpty)
    }

    func testDelayedTimerUsesThresholdTimestampAcrossMidnight() {
        var engine = CountingEngine()
        let midnight = Date(timeIntervalSince1970: 1_704_153_600)
        _ = engine.observe(.closed, at: 0, date: midnight.addingTimeInterval(-2))
        _ = engine.observe(.halfOpen, at: 1, date: midnight.addingTimeInterval(-0.5))
        let events = engine.observe(.fullyOpen, at: 3, date: midnight.addingTimeInterval(2))
        XCTAssertEqual(events.map(\.kind), [.halfOpen, .fullyOpen])
        XCTAssertEqual(events.first?.countedAt, midnight.addingTimeInterval(0.5))
        var archive = RecordArchive(mode: .demo)
        archive.timezoneIdentifier = "GMT"
        archive.events = events
        XCTAssertEqual(archive.count(.halfOpen, on: midnight), 1)
        XCTAssertEqual(archive.count(.halfOpen, on: midnight.addingTimeInterval(-1)), 0)
    }

    func testGapDoesNotConfirmExpiredPendingHalf() {
        var engine = CountingEngine()
        _ = engine.observe(.closed, at: 0, date: epoch)
        _ = engine.observe(.halfOpen, at: 1, date: epoch)
        XCTAssertTrue(engine.observe(nil, at: 4, date: epoch).isEmpty)
        XCTAssertTrue(engine.observe(.closed, at: 5, date: epoch).isEmpty)
        XCTAssertTrue(engine.advance(to: 10).isEmpty)
    }
}
