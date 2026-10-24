import SwiftUI
import WidgetKit

struct FoldEntry: TimelineEntry {
    let date: Date
    let value: WidgetValue
}

struct FoldProvider: TimelineProvider {
    func placeholder(in context: Context) -> FoldEntry {
        FoldEntry(date: .now, value: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (FoldEntry) -> Void) {
        let now = Date()
        let value = context.isPreview ? WidgetValue.preview : current(at: now)
        completion(FoldEntry(date: now, value: value))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FoldEntry>) -> Void) {
        let now = Date()
        guard let snapshot = try? WidgetSnapshotRepository.shared?.load() else {
            completion(Timeline(entries: [FoldEntry(date: now, value: WidgetValue(date: now))],
                                policy: .after(now.addingTimeInterval(900))))
            return
        }
        let entries = snapshot.timelineDates(from: now).map { date in
            FoldEntry(date: date, value: snapshot.value(at: date))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(1800))))
    }

    private func current(at date: Date) -> WidgetValue {
        (try? WidgetSnapshotRepository.shared?.load())?.value(at: date) ?? WidgetValue(date: date)
    }
}

struct FoldEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FoldEntry
    let variant: FoldWidgetVariant

    var body: some View {
        FoldWidgetContent(value: entry.value, variant: variant, family: family)
            .containerBackground(WidgetPalette.background, for: .widget)
    }
}

struct FoldCountWidget: Widget {
    let kind = "FoldLog.Count"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoldProvider()) { entry in
            FoldEntryView(entry: entry, variant: .count)
        }
        .configurationDisplayName("今日折叠")
        .description("查看今日已保存的折叠次数与每日上限。演示记录会单独标识。")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

struct FoldRemainingWidget: Widget {
    let kind = "FoldLog.Remaining"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoldProvider()) { entry in
            FoldEntryView(entry: entry, variant: .remaining)
        }
        .configurationDisplayName("剩余折叠")
        .description("查看距离个人每日上限的剩余次数。轻点可调整折叠目标。")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

@main
struct FoldLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        FoldCountWidget()
        FoldRemainingWidget()
    }
}

#Preview("今日折叠", as: .systemSmall) { FoldCountWidget() } timeline: {
    FoldEntry(date: .now, value: .preview)
}
#Preview("剩余折叠", as: .accessoryCircular) { FoldRemainingWidget() } timeline: {
    FoldEntry(date: .now, value: .preview)
}
