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

    private var remaining: String { value.remaining.map(String.init) ?? "—" }
    private var notice: String? {
        if value.count == nil { return "打开折记同步" }
        if value.recordingPaused { return "记录已暂停" }
        if value.needsSync { return "待同步" }
        if value.limit == nil { return "未设每日上限" }
        return nil
    }

    private var accessibilitySummary: String {
        guard value.count != nil else { return "剩余折叠次数暂不可用，请打开折记同步。" }
        let result = value.remaining.map { "今日剩余折叠 \($0) 次。" } ?? "未设置每日上限。"
        return "\(value.sourceTitle)，" + result + (notice.map { "\($0)。" } ?? "")
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "rectangle.portrait")
                    .foregroundStyle(WidgetPalette.gold).accessibilityHidden(true)
                Text("剩余折叠").fontWeight(.medium)
            }
            .font(.caption)
            Spacer(minLength: 0)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(remaining)
                    .font(.system(size: 50, weight: .semibold, design: .rounded))
                    .monospacedDigit().minimumScaleFactor(0.4).lineLimit(1)
                    .foregroundStyle(value.remaining == nil ? Color.secondary : WidgetPalette.gold)
                if value.remaining != nil {
                    Text("次").font(.caption).foregroundStyle(WidgetPalette.secondary)
                }
            }
            if let notice {
                Text(notice).font(.caption).foregroundStyle(WidgetPalette.secondary)
                    .lineLimit(1).minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            if value.count == nil { Text("打开折记同步") }
            else if value.remaining == nil { Text("折叠 · 未设目标") }
            else { Text("折叠剩余 \(remaining) 次") }
        } icon: { Image(systemName: "rectangle.portrait") }
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Text("剩余").font(.system(size: 9, weight: .medium))
                Text(remaining).font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit().lineLimit(1).minimumScaleFactor(0.4)
                if let notice {
                    Text(notice).font(.system(size: 8))
                        .lineLimit(1).minimumScaleFactor(0.65)
                }
            }
            .frame(width: 44, height: 44)
        }
    }
}
