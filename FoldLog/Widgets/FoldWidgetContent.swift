import SwiftUI
import WidgetKit

enum FoldWidgetVariant { case count, remaining }

enum WidgetPalette {
    static let gold = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.85, green: 0.72, blue: 0.46, alpha: 1)
            : UIColor(red: 0.525, green: 0.384, blue: 0.114, alpha: 1)
    })
    static let background = Color(uiColor: .systemBackground)
}

/// The extension and in-app style gallery use these same native views.
struct FoldWidgetContent: View {
    let value: WidgetValue
    let variant: FoldWidgetVariant
    let family: WidgetFamily

    private var isRemaining: Bool { variant == .remaining }
    private var title: String { isRemaining ? "剩余折叠" : "今日折叠" }
    private var number: String { (isRemaining ? value.remaining : value.count).map(String.init) ?? "—" }
    private var destination: URL { (isRemaining && value.count != nil ? WidgetDestination.goal : .today).url }

    var body: some View {
        Group {
            switch family {
            case .accessoryInline: inline
            case .accessoryCircular: circular
            default: small
            }
        }
        // Widget canvases have a fixed system size; the complete value remains available to VoiceOver.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .widgetURL(destination)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.accessibilitySummary)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            Spacer(minLength: 0)
            Text(number)
                .font(.system(size: 50, weight: .semibold, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.45).lineLimit(1)
                .contentTransition(.numericText())
            Text(isRemaining ? value.goalStatus : countDetail)
                .font(.caption).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            freshness
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "rectangle.portrait").foregroundStyle(WidgetPalette.gold)
            Text(title).fontWeight(.medium)
            Spacer(minLength: 2)
            if value.mode == .demo {
                Text("演示").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .font(.caption).lineLimit(1).minimumScaleFactor(0.75)
    }

    private var countDetail: String {
        if value.count == nil { return "打开 App 同步" }
        if value.exceeded > 0 { return "已超出 \(value.exceeded) 次 · 上限 \(value.limit!)" }
        return value.remaining.map { "剩余 \($0) 次 · 上限 \(value.limit!)" } ?? "未设置每日上限"
    }

    private var freshness: some View {
        HStack(spacing: 4) {
            if value.count == nil || value.needsSync || value.recordingPaused {
                Image(systemName: "arrow.clockwise")
                Text(value.status)
            } else {
                Text(value.mode == .demo ? "演示" : "已保存")
                if let date = value.updatedAt {
                    Text(date, style: .time).monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
    }

    private var inline: some View {
        Label {
            if value.count == nil { Text("折记 · 打开 App 同步") }
            else if isRemaining {
                Text(value.remaining.map { "\(value.mode == .demo ? "演示 · " : "")折叠剩余 \($0) 次" }
                     ?? "\(value.mode == .demo ? "演示 · " : "")折叠 · 未设目标")
            } else {
                Text("\(value.mode == .demo ? "演示 · " : "")折叠 \(value.count!) 次")
            }
        } icon: { Image(systemName: "rectangle.portrait") }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if value.limit != nil && value.count != nil {
                Gauge(value: isRemaining ? 1 - value.progress : value.progress) { Text(title) } currentValueLabel: {
                    circularNumber
                }
                .gaugeStyle(.accessoryCircularCapacity)
            } else { circularNumber }
        }
    }

    private var circularNumber: some View {
        VStack(spacing: 0) {
            Text(value.mode == .demo ? (isRemaining ? "演示余" : "演示折叠") : (isRemaining ? "剩余" : "折叠"))
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.75)
            Text(number).font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.45)
            if isRemaining && value.limit == nil {
                Text("未设置").font(.system(size: 9))
            }
        }
        .padding(.horizontal, 4)
    }
}
