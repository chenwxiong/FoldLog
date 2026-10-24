import Foundation

enum InputMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case demo, device
    var id: String { rawValue }
    var title: String { self == .demo ? "演示模式" : "设备记录" }
}

struct DailyGoal: Codable, Identifiable, Sendable {
    var id = UUID()
    let metric: FoldPose
    let limit: Int?
    let effectiveFrom: Date
}

struct RecordArchive: Codable, Sendable {
    var schemaVersion = 1
    let mode: InputMode
    var createdAt = Date()
    var timezoneIdentifier = TimeZone.current.identifier
    var events: [FoldEvent] = []
    var goals: [DailyGoal] = []

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .gmt
        return calendar
    }

    func count(_ metric: FoldPose, on date: Date? = nil) -> Int {
        events.filter {
            $0.kind == metric && (date == nil || calendar.isDate($0.countedAt, inSameDayAs: date!))
        }.count
    }

    func limit(for metric: FoldPose, on date: Date) -> Int? {
        let day = calendar.startOfDay(for: date)
        return goals.filter { $0.metric == metric && $0.effectiveFrom <= day }
            .max(by: { $0.effectiveFrom < $1.effectiveFrom })?.limit
    }

    mutating func setLimit(_ limit: Int?, for metric: FoldPose, from date: Date) {
        let day = calendar.startOfDay(for: date)
        goals.removeAll { $0.metric == metric && $0.effectiveFrom >= day }
        goals.append(DailyGoal(metric: metric, limit: limit, effectiveFrom: day))
    }

    func days(endingAt date: Date, count: Int) -> [Date] {
        let end = calendar.startOfDay(for: date)
        return (0..<count).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: end) }
    }

    func validate(expectedMode: InputMode) throws {
        guard schemaVersion == 1, mode == expectedMode,
              TimeZone(identifier: timezoneIdentifier) != nil,
              Set(events.map(\.id)).count == events.count,
              goals.allSatisfy({ $0.limit == nil || $0.limit! > 0 }) else {
            throw ArchiveError.incompatible
        }
    }
}

enum ArchiveError: Error { case incompatible }

struct ArchiveRepository {
    let directory: URL

    func url(for mode: InputMode) -> URL { directory.appendingPathComponent("\(mode.rawValue).json") }

    func load(_ mode: InputMode) throws -> RecordArchive {
        let file = url(for: mode)
        guard FileManager.default.fileExists(atPath: file.path) else { return RecordArchive(mode: mode) }
        let archive = try JSONDecoder().decode(RecordArchive.self, from: Data(contentsOf: file))
        try archive.validate(expectedMode: mode)
        return archive
    }

    func save(_ archive: RecordArchive) throws {
        try archive.validate(expectedMode: archive.mode)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(archive).write(to: url(for: archive.mode), options: .atomic)
    }
}
