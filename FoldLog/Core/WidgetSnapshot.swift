import Foundation

/// A small read-only projection. Widgets never read or mutate the original event archive.
struct WidgetSnapshot: Codable, Sendable {
    static let version = 1
    var schemaVersion = version
    let mode: InputMode
    let updatedAt: Date
    let day: Date
    let timezoneIdentifier: String
    let folds: Int?
    let goals: [DailyGoal]
    let recordingPaused: Bool

    init(archive: RecordArchive, at date: Date, readable: Bool = true, recordingPaused: Bool = false) {
        mode = archive.mode
        updatedAt = date
        day = archive.calendar.startOfDay(for: date)
        timezoneIdentifier = archive.timezoneIdentifier
        folds = readable ? archive.count(.closed, on: date) : nil
        goals = readable ? archive.goals.filter { $0.metric == .closed } : []
        self.recordingPaused = recordingPaused
    }

    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timezoneIdentifier) ?? .gmt
        return calendar
    }

    func value(at date: Date) -> WidgetValue {
        let targetDay = calendar.startOfDay(for: date)
        let count = folds.map { targetDay == day ? $0 : 0 }
        let limit = goals.filter { $0.effectiveFrom <= targetDay }
            .max(by: { $0.effectiveFrom < $1.effectiveFrom })?.limit
        return WidgetValue(date: date, mode: mode, count: count, limit: limit,
                           updatedAt: updatedAt, needsSync: targetDay != day, recordingPaused: recordingPaused)
    }

    /// Calendar arithmetic handles local midnight and 23/25-hour DST days.
    func timelineDates(from date: Date, days: Int = 7) -> [Date] {
        [date] + (1...max(1, days)).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: date))
        }
    }

    func validate() throws {
        guard schemaVersion == Self.version, TimeZone(identifier: timezoneIdentifier) != nil,
              folds == nil || folds! >= 0,
              goals.allSatisfy({ $0.metric == .closed && ($0.limit == nil || $0.limit! > 0) }) else {
            throw ArchiveError.incompatible
        }
    }
}

struct WidgetValue: Sendable {
    let date: Date
    var mode: InputMode?
    var count: Int?
    var limit: Int?
    var updatedAt: Date?
    var needsSync = false
    var recordingPaused = false

    var remaining: Int? { count.flatMap { count in limit.map { max(0, $0 - count) } } }
    var exceeded: Int { max(0, (count ?? 0) - (limit ?? Int.max)) }
    var progress: Double { guard let count, let limit else { return 0 }; return min(1, Double(count) / Double(limit)) }
    var sourceTitle: String { mode == .demo ? "演示" : "设备记录" }
    var status: String {
        if count == nil { return "打开折记同步" }
        if recordingPaused { return "记录已暂停" }
        if needsSync { return "今日尚未同步" }
        return mode == .demo ? "演示记录" : "已保存记录"
    }
    var goalStatus: String {
        guard count != nil else { return "打开 App 同步" }
        guard let remaining else { return "未设置目标" }
        if exceeded > 0 { return "已超出 \(exceeded) 次" }
        return remaining == 0 ? "已达上限" : "每日上限 \(limit!) 次"
    }
    var accessibilitySummary: String {
        guard let count else { return "折叠记录暂不可用，请打开折记同步。" }
        return "\(sourceTitle)，今日已记录折叠 \(count) 次。" +
            (remaining.map { "剩余 \($0) 次。\(goalStatus)。" } ?? "未设置每日上限。") +
            "\(status)。"
    }

    static var preview: WidgetValue {
        WidgetValue(date: .now, mode: .demo, count: 24, limit: 60, updatedAt: .now)
    }
}

struct WidgetSnapshotRepository {
    static let groupIdentifier = "group.app.foldlog.preview"
    static let fileName = "fold-widget-v1.json"
    let directory: URL
    var url: URL { directory.appendingPathComponent(Self.fileName) }

    static var shared: WidgetSnapshotRepository? {
        #if os(iOS)
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)
            .map { WidgetSnapshotRepository(directory: $0) }
        #else
        nil
        #endif
    }

    func save(_ snapshot: WidgetSnapshot) throws {
        try snapshot.validate()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(snapshot)
        #if os(iOS)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: url, options: .atomic)
        #endif
    }

    func load() throws -> WidgetSnapshot {
        let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: Data(contentsOf: url))
        try snapshot.validate()
        return snapshot
    }
}

enum WidgetDestination: Equatable {
    case today, goal
    var url: URL { URL(string: self == .today ? "foldlog://today" : "foldlog://goal/closed")! }
    init?(url: URL) {
        guard url.scheme == "foldlog" else { return nil }
        switch (url.host, url.path) {
        case ("today", ""), ("today", "/"): self = .today
        case ("goal", "/closed"): self = .goal
        default: return nil
        }
    }
}
