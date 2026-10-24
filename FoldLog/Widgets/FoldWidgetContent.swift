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
    private var usesLargeNumbers: Bool { max(value.remaining ?? 0, value.limit ?? 0) >= 10_000 }

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
        .widgetURL(WidgetDestination.today.url)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.accessibilitySummary)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(number)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.45).lineLimit(1)
                Text("次").font(.caption).foregroundStyle(WidgetPalette.secondary)
            }
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("剩余").font(.caption)
                Text(remaining)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
                Text("次").font(.caption)
                Spacer(minLength: 4)
                if !usesLargeNumbers {
                    Text(value.limit.map { "上限 \($0)" } ?? (value.count == nil ? "待同步" : "未设目标"))
                        .font(.caption2).foregroundStyle(WidgetPalette.secondary)
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
            }
            .foregroundStyle(value.remaining == nil ? Color.secondary : WidgetPalette.gold)
            .lineLimit(1)
            if value.count != nil && value.limit != nil {
                ProgressView(value: value.progress)
                    .tint(WidgetPalette.gold)
                    .accessibilityHidden(true)
            }
            freshness
        }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(systemName: "rectangle.portrait").foregroundStyle(WidgetPalette.gold).accessibilityHidden(true)
            Text("今日折叠").fontWeight(.medium)
            Spacer(minLength: 2)
            if value.mode == .demo {
                Text("演示").font(.caption2).foregroundStyle(WidgetPalette.secondary)
            }
        }
        .font(.caption).lineLimit(1).minimumScaleFactor(0.75)
    }

    private var freshness: some View {
        HStack(spacing: 4) {
            if usesLargeNumbers, let limit = value.limit {
                Text("上限 \(limit)").fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 4)
                Text(value.recordingPaused ? "记录暂停" : value.needsSync ? "待同步" :
                     value.exceeded > 0 ? "超 \(value.exceeded)" : value.remaining == 0 ? "已达上限" : "已保存")
            } else if value.count == nil || value.needsSync || value.recordingPaused {
                Image(systemName: "arrow.clockwise")
                Text(value.status)
            } else {
                Text(value.exceeded > 0 ? "超出 \(value.exceeded) 次" : value.remaining == 0 ? "已达上限" : "更新")
                if let date = value.updatedAt {
                    Text(date, style: .time).monospacedDigit()
                }
            }
            Spacer(minLength: 0)
        }
        .font(.caption2).foregroundStyle(WidgetPalette.secondary).lineLimit(1).minimumScaleFactor(0.7)
    }

    private var inline: some View {
        Label {
            if value.count == nil { Text("折记 · 打开 App 同步") }
            else { Text(inlineSummary) }
        } icon: { Image(systemName: "rectangle.portrait") }
    }

    private var inlineSummary: String {
        let source = value.mode == .demo ? "演示 · " : ""
        let goal = value.remaining.map { "余 \($0)" } ?? "未设目标"
        let overflow = value.exceeded > 0 ? " · 超 \(value.exceeded)" : ""
        return "\(source)折叠\(number) · \(goal)\(overflow)"
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            if value.limit != nil && value.count != nil {
                Gauge(value: value.progress) { EmptyView() }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .accessibilityHidden(true)
            }
            // Keep the label outside Gauge's currentValueLabel sizing so long counts can scale.
            circularNumber.frame(width: 44, height: 44)
        }
    }

    private var circularNumber: some View {
        VStack(spacing: 0) {
            Text(value.count == nil ? "待同步" : value.mode == .demo ? "演示" : "折叠")
                .font(.system(size: 8, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.75)
            Text(number).font(.system(size: 19, weight: .semibold, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.45)
            Text(value.remaining == nil ? (value.count == nil ? "打开折记" : "未设目标") : "余 \(remaining)")
                .font(.system(size: 9, weight: .medium))
                .lineLimit(1).minimumScaleFactor(0.65)
        }
    }
}
