import Foundation

enum FoldPose: String, Codable, CaseIterable, Identifiable, Sendable {
    case closed, halfOpen, fullyOpen

    var id: String { rawValue }
    var title: String {
        switch self {
        case .closed: "折叠"
        case .halfOpen: "半开"
        case .fullyOpen: "全开"
        }
    }
    var stateTitle: String { self == .closed ? "合拢" : title }
    var symbol: String {
        switch self {
        case .closed: "rectangle.portrait"
        case .halfOpen: "book"
        case .fullyOpen: "rectangle.split.2x1"
        }
    }
}

struct FoldEvent: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    let kind: FoldPose
    let countedAt: Date
}

/// A single continuous observation session. Time is monotonic, dates are for daily grouping.
struct CountingEngine: Sendable {
    private(set) var pose: FoldPose?
    private(set) var halfOpenDeadline: TimeInterval?
    private var halfOpenCountedAt: Date?

    mutating func invalidate() {
        pose = nil
        halfOpenDeadline = nil
        halfOpenCountedAt = nil
    }

    mutating func observe(_ newPose: FoldPose?, at time: TimeInterval, date: Date) -> [FoldEvent] {
        // A gap cannot establish that the preceding half-open interval was continuous.
        guard let newPose else {
            invalidate()
            return []
        }
        var events = advance(to: time)
        guard let oldPose = pose else {
            pose = newPose
            return events
        }
        guard oldPose != newPose else { return events }
        halfOpenDeadline = nil
        halfOpenCountedAt = nil
        switch newPose {
        case .closed, .fullyOpen:
            events.append(FoldEvent(kind: newPose, countedAt: date))
        case .halfOpen:
            if oldPose == .closed {
                halfOpenDeadline = time + 1
                halfOpenCountedAt = date.addingTimeInterval(1)
            }
        }
        pose = newPose
        return events
    }

    mutating func advance(to time: TimeInterval) -> [FoldEvent] {
        guard pose == .halfOpen, let deadline = halfOpenDeadline,
              time >= deadline, let countedAt = halfOpenCountedAt else { return [] }
        halfOpenDeadline = nil
        halfOpenCountedAt = nil
        return [FoldEvent(kind: .halfOpen, countedAt: countedAt)]
    }
}
