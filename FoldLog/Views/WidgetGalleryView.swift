import SwiftUI
import WidgetKit

struct WidgetGalleryView: View {
    @Environment(AppStore.self) private var store
    @State private var showExample = false
    @State private var example = WidgetExample.normal

    private enum WidgetExample: String, CaseIterable, Identifiable {
        case normal = "目标内", unset = "未设目标", reached = "达到上限", exceeded = "超出上限", large = "大数字", unavailable = "待同步"
        var id: Self { self }
        var value: WidgetValue {
            var value = WidgetValue.preview
            switch self {
            case .normal: break
            case .unset: value.limit = nil
            case .reached: value.count = 60
            case .exceeded: value.count = 63
            case .large: value.count = 123_456; value.limit = 999_999
            case .unavailable: value.count = nil; value.limit = nil
            }
            return value
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("抬眼，心中有数。")
                            .font(.title2.weight(.semibold))
                        Text("一个小组件，同时查看今日折叠与剩余次数。")
                            .foregroundStyle(.secondary)
                    }
                    Picker("预览数据", selection: $showExample) {
                        Text("当前记录").tag(false)
                        Text("示例效果").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("widget-preview-source")
                    if showExample {
                        Picker("示例状态", selection: $example) {
                            ForEach(WidgetExample.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .accessibilityIdentifier("widget-preview-state")
                    }
                    let value = showExample ? example.value : store.widgetValue(at: timeline.date)
                    Text(showExample ? "样式示例 · 演示数据，不写入记录" : "当前来源：\(store.mode.title)")
                        .font(.caption).foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("桌面 · 小号").font(.headline)
                        small(value)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("锁屏 · 圆形 / 单行").font(.headline)
                        FoldWidgetContent(value: value, family: .accessoryCircular)
                            .frame(width: 64, height: 64)
                            .accessibilityIdentifier("widget-summary-circular-preview")
                        FoldWidgetContent(value: value, family: .accessoryInline)
                            .font(.subheadline)
                            .accessibilityIdentifier("widget-summary-inline-preview")
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("添加到桌面").font(.headline)
                        Text("长按桌面空白处 → 编辑 → 添加小组件 → 搜索“折记” → 选择“今日折叠”。")
                        Text("添加到锁屏").font(.headline)
                        Text("长按锁屏 → 自定 → 锁定屏幕 → 点按时间上方或下方的小组件区域 → 选择“折记”。")
                        Text("轻点小组件打开今日，在 App 中调整每日上限。进度条表示今日已使用的次数，达到上限后继续计数。")
                    }
                    .font(.subheadline)
                    VStack(alignment: .leading, spacing: 10) {
                        Label("显示已保存的前台记录", systemImage: "info.circle").font(.subheadline.weight(.medium))
                        Text("小组件不会在后台采集开合。数据随 App 保存后请求刷新，实际更新时间由系统安排。次日按统计时区归零，并应用已设置的次日目标。")
                        Text("演示与设备数据分别保存，小组件跟随 App 当前来源。重启设备后，需先解锁一次以读取共享记录。")
                        if let error = store.widgetSyncError {
                            Text(error)
                        } else if let updated = store.widgetUpdatedAt {
                            Text("最近共享：\(updated.formatted(date: .omitted, time: .shortened))")
                        }
                        Button("同步已保存记录") { store.publishWidgets() }
                            .buttonStyle(.bordered).tint(Theme.accent)
                            .accessibilityIdentifier("widget-sync")
                    }
                    .font(.footnote).foregroundStyle(.secondary)
                }
                .frame(maxWidth: 540, alignment: .leading)
                .padding(20).frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("widget-gallery-scroll")
            .safeAreaPadding(.bottom, 16)
            .background(Theme.background)
        }
        .navigationTitle("桌面与锁屏").navigationBarTitleDisplayMode(.inline)
    }

    private func small(_ value: WidgetValue) -> some View {
        FoldWidgetContent(value: value, family: .systemSmall)
            .padding(16).frame(width: 156, height: 156)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
            .accessibilityIdentifier("widget-summary-small-preview")
    }
}
