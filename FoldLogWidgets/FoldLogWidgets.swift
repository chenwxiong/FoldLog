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

    var body: some View {
        FoldWidgetContent(value: entry.value, family: family)
            .containerBackground(WidgetPalette.background, for: .widget)
    }
}

struct FoldCountWidget: Widget {
    let kind = "FoldLog.Count"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FoldProvider()) { entry in
            FoldEntryView(entry: entry)
        }
        .configurationDisplayName("今日折叠")
        .description("同时查看今日折叠与剩余次数。轻点打开今日记录。")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

@main
struct FoldLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        FoldCountWidget()
    }
}

#Preview("今日折叠", as: .systemSmall) { FoldCountWidget() } timeline: {
    FoldEntry(date: .now, value: .preview)
}
#Preview("锁屏今日与剩余", as: .accessoryCircular) { FoldCountWidget() } timeline: {
    FoldEntry(date: .now, value: .preview)
}
