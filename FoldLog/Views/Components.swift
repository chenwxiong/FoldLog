import SwiftUI

enum Theme {
    // Gold is an accent; text and numbers retain semantic system colors.
    static let accent = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return traits.accessibilityContrast == .high
                ? UIColor(red: 0.96, green: 0.84, blue: 0.55, alpha: 1)
                : UIColor(red: 0.85, green: 0.72, blue: 0.46, alpha: 1)
        }
        return traits.accessibilityContrast == .high
            ? UIColor(red: 0.38, green: 0.26, blue: 0.06, alpha: 1)
            : UIColor(red: 0.525, green: 0.384, blue: 0.114, alpha: 1)
    })
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .black : UIColor(white: 0.96, alpha: 1)
    })
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let contentWidth: CGFloat = 1080
}

struct Card<Content: View>: View {
    private let padding: CGFloat
    private let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(.primary.opacity(0.035), lineWidth: 0.5)
                    .allowsHitTesting(false)
            }
    }
}

struct SectionTitle: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer(minLength: 12)
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct ModeBadge: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Label {
            Text(store.mode.title).foregroundStyle(.primary)
        } icon: {
            Image(systemName: store.mode == .demo ? "play.circle.fill" : "iphone.gen3")
                .foregroundStyle(Theme.accent)
        }
        .font(.caption.weight(.medium))
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Theme.accent.opacity(0.09), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct PoseSymbol: View {
    let pose: FoldPose
    var size: CGFloat = 26

    var body: some View {
        Image(systemName: pose.symbol)
            .font(.system(size: size, weight: .regular))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Theme.accent)
            .frame(width: size + 24, height: size + 24)
            .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)
    }
}

struct SettingsSymbol: View {
    let name: String
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 30

    var body: some View {
        Image(systemName: name)
            .font(.body.weight(.medium))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(Theme.accent)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct RecordScopeNote: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Label(store.mode == .demo
              ? "模拟记录与设备记录分开保存。"
              : "仅包含前台有效记录，未覆盖时段不会补记。",
              systemImage: "info.circle")
            .font(.footnote).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StorageErrorView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if let error = store.storageError {
            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Label("记录已暂停", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(error).font(.subheadline)
                    Button("重试读取") { store.retry() }.buttonStyle(.bordered)
                }
            }
            .foregroundStyle(.red)
        }
    }
}
