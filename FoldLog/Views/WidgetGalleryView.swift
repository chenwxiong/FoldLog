import SwiftUI
import WidgetKit

struct WidgetGalleryView: View {
    @Environment(AppStore.self) private var store
    @State private var showExample = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("抬眼，心中有数。")
                            .font(.title2.weight(.semibold))
                        Text("把今日折叠与剩余次数，放在桌面或锁屏。")
                            .foregroundStyle(.secondary)
                    }
                    Picker("预览数据", selection: $showExample) {
                        Text("当前记录").tag(false)
                        Text("示例效果").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("widget-preview-source")
                    let value = showExample ? WidgetValue.preview : store.widgetValue(at: timeline.date)
                    Text(showExample ? "样式示例 · 演示数据，不写入记录" : "当前来源：\(store.mode.title)")
                        .font(.caption).foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("桌面 · 小号").font(.headline)
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 16) {
                                small(value, variant: .count)
                                small(value, variant: .remaining)
                            }
                            VStack(alignment: .leading, spacing: 16) {
                                small(value, variant: .count)
                                small(value, variant: .remaining)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("锁屏 · 圆形 / 单行").font(.headline)
                        HStack(spacing: 24) {
                            FoldWidgetContent(value: value, variant: .remaining, family: .accessoryCircular)
                                .frame(width: 72, height: 72)
                            FoldWidgetContent(value: value, variant: .count, family: .accessoryCircular)
                                .frame(width: 72, height: 72)
                        }
                        FoldWidgetContent(value: value, variant: .count, family: .accessoryInline)
                            .font(.subheadline)
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("添加到桌面").font(.headline)
                        Text("长按桌面空白处 → 编辑 → 添加小组件 → 搜索“折记” → 选择“今日折叠”或“剩余折叠”。")
                        Text("添加到锁屏").font(.headline)
                        Text("长按锁屏 → 自定 → 锁定屏幕 → 点按时间上方或下方的小组件区域 → 选择“折记”。")
                        Text("轻点次数打开今日；轻点剩余次数打开折叠目标。目标是个人每日上限，达到后继续计数。")
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

    private func small(_ value: WidgetValue, variant: FoldWidgetVariant) -> some View {
        FoldWidgetContent(value: value, variant: variant, family: .systemSmall)
            .padding(16).frame(width: 156, height: 168)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24))
            .accessibilityIdentifier(variant == .count ? "widget-count-small-preview" : "widget-remaining-small-preview")
    }
}
