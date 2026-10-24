import SwiftUI
import WidgetKit

enum WidgetPalette {
    static let gold = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.85, green: 0.72, blue: 0.46, alpha: 1)
            : UIColor(red: 0.525, green: 0.384, blue: 0.114, alpha: 1)
    })
    static let background = Color(uiColor: .systemBackground)
    static let secondary = Color.primary.opacity(0.65)
}

/// The extension and in-app style gallery use these same native views.
struct FoldWidgetContent: View {
    let value: WidgetValue
    let family: WidgetFamily

    private var number: String { value.count.map(String.init) ?? "—" }
    private var remaining: String { value.remaining.map(String.init) ?? "—" }
    private var notice: String? {
        if value.count == nil { return "打开折记同步" }
        if value.recordingPaused { return "记录已暂停" }
        if value.needsSync { return "待同步" }
        if value.limit == nil { return "未设目标" }
        return nil
    }

    private var accessibilitySummary: String {
        guard let count = value.count else { return "折叠记录暂不可用，请打开折记同步。" }
        let goal = value.remaining.map { "剩余 \($0) 次。" } ?? "未设目标。"
        let status = value.recordingPaused || value.needsSync ? (notice.map { "\($0)。" } ?? "") : ""
        return "\(value.sourceTitle)，今日已记录折叠 \(count) 次。" + goal + status
    }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline: inline
            case .accessoryCircular: circular
            default: small
            }
        }
        // Fixed widget canvases scale long values; VoiceOver reads the complete value and source.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .widgetURL(WidgetDestination.today.url)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "rectangle.portrait")
                    .foregroundStyle(WidgetPalette.gold).accessibilityHidden(true)
                Text("今日折叠").fontWeight(.medium)
            }
            .font(.caption)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(number)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                if value.count != nil {
                    Text("次").font(.caption).foregroundStyle(WidgetPalette.secondary)
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("剩余").font(.caption)
                Text(remaining)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                if value.remaining != nil { Text("次").font(.caption) }
            }
            .foregroundStyle(value.remaining == nil ? Color.secondary : WidgetPalette.gold)
            if value.count != nil && value.limit != nil {
                ProgressView(value: value.progress)
                    .tint(WidgetPalette.gold).accessibilityHidden(true)
            }
            if let notice {
                Text(notice).font(.caption2).foregroundStyle(WidgetPalette.secondary)
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            if value.count == nil { Text("打开折记同步") }
            else { Text("折叠 \(number) · \(value.remaining.map { "余 \($0)" } ?? "未设目标")") }
        } icon: { Image(systemName: "rectangle.portrait") }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if value.count != nil && value.limit != nil {
                Gauge(value: value.progress) { EmptyView() }
                    .gaugeStyle(.accessoryCircularCapacity).accessibilityHidden(true)
            }
            // The independent label can scale long numbers without Gauge truncating them.
            VStack(spacing: 0) {
                Text(value.count == nil ? "待同步" : "折叠")
                    .font(.system(size: 8, weight: .medium))
                Text(number).font(.system(size: 19, weight: .semibold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
                Text(value.remaining.map { "余 \($0)" } ?? (value.count == nil ? "打开折记" : "未设目标"))
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(width: 44, height: 44)
        }
    }
}
