import SwiftUI

private enum SettingsCategory: String, CaseIterable, Identifiable {
    case recording, goals, widgets, appearance, data, about

    var id: String { rawValue }
    var title: String {
        switch self {
        case .recording: "记录方式"
        case .goals: "每日目标"
        case .widgets: "小组件"
        case .appearance: "外观"
        case .data: "数据"
        case .about: "关于与规则"
        }
    }
    var symbol: String {
        switch self {
        case .recording: "iphone.gen3"
        case .goals: "flag"
        case .widgets: "square.grid.2x2"
        case .appearance: "circle.lefthalf.filled"
        case .data: "externaldrive"
        case .about: "text.book.closed"
        }
    }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage("appearance") private var appearance = "system"
    @State private var category: SettingsCategory? = .goals
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var editingGoal: FoldPose?
    @State private var showClearConfirmation = false

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= 700 && !dynamicTypeSize.isAccessibilitySize {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    List(SettingsCategory.allCases, selection: $category) { item in
                        NavigationLink(value: item) {
                            Label { Text(item.title) } icon: { SettingsSymbol(name: item.symbol) }
                                .frame(minHeight: 44)
                        }
                        .accessibilityIdentifier("settings-category-\(item.rawValue)")
                    }
                    .listStyle(.sidebar)
                    .scrollContentBackground(.hidden)
                    .background(Theme.background)
                    .navigationTitle("设置")
                    .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 300)
                    .accessibilityIdentifier("settings-categories")
                } detail: {
                    NavigationStack {
                        settingsForm(category: category ?? .goals)
                            .navigationTitle((category ?? .goals).title)
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .id(category)
                }
                .navigationSplitViewStyle(.balanced)
            } else {
                NavigationStack {
                    settingsForm(category: nil)
                        .navigationTitle("设置")
                }
            }
        }
        .sheet(item: $editingGoal) { metric in
            GoalEditorSheet(metric: metric)
        }
        .confirmationDialog("清空\(store.mode.title)的全部次数和目标？", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("清空数据", role: .destructive) { store.clearCurrentRecords() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("其他模式的数据会保留。清空后无法撤销，建议先导出记录。")
        }
    }

    private func settingsForm(category: SettingsCategory?) -> some View {
        Form {
            if store.storageError != nil {
                Section { StorageErrorView() }
            }
            if category == nil || category == .recording { recordingSection }
            if category == nil || category == .goals { goalsSection }
            if category == nil || category == .widgets { widgetsSection }
            if category == nil || category == .appearance { appearanceSection }
            if category == nil || category == .data { dataSection }
            if category == nil || category == .about { aboutSections }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(Theme.background)
        .accessibilityIdentifier("settings-detail-\(category?.rawValue ?? "all")")
    }

    private var recordingSection: some View {
        Section {
            Picker(selection: Binding(get: { store.mode }, set: store.changeMode)) {
                ForEach(InputMode.allCases) { Text($0.title).tag($0) }
            } label: {
                Label { Text("记录来源") } icon: { SettingsSymbol(name: "iphone.gen3") }
            }
            .accessibilityIdentifier("input-mode")
        } header: { Text("记录方式") } footer: {
            Text("演示与设备记录分别保存。设备模式仅记录 App 前台的有效开合。")
        }
    }

    private var goalsSection: some View {
        Section {
            ForEach(FoldPose.allCases) { metric in
                Button { editingGoal = metric } label: {
                    HStack(spacing: 12) {
                        SettingsSymbol(name: metric.symbol)
                        Text("\(metric.title)目标").foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        Text(store.archive.limit(for: metric, on: Date()).map { "每日上限 \($0) 次" } ?? "未设置")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                    .frame(minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("goal-\(metric.rawValue)")
            }
        } header: { Text("每日目标") } footer: {
            Text("达到自定上限后仍会记录。次数不代表折痕程度或设备寿命。")
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            Picker(selection: $appearance) {
                Text("跟随系统").tag("system")
                Text("浅色").tag("light")
                Text("深色").tag("dark")
            } label: {
                Label { Text("显示模式") } icon: { SettingsSymbol(name: "circle.lefthalf.filled") }
            }
        }
    }

    private var widgetsSection: some View {
        Section {
            NavigationLink {
                WidgetGalleryView()
            } label: {
                Label { Text("桌面与锁屏小组件") } icon: { SettingsSymbol(name: "square.grid.2x2") }
            }
            .accessibilityIdentifier("widget-gallery")
            if let error = store.widgetSyncError {
                Text(error).font(.footnote).foregroundStyle(.secondary)
                Button("重试同步小组件") { store.publishWidgets() }
            }
        } header: { Text("小组件") } footer: {
            Text("展示今日折叠与个人上限剩余次数，跟随当前记录来源。")
        }
    }

    private var dataSection: some View {
        Section("数据") {
            LabeledContent("记录起点", value: store.archive.createdAt.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("统计时区", value: store.archive.timezoneIdentifier)
            if let url = store.exportURL() {
                ShareLink(item: url) {
                    Label { Text("导出当前模式记录").foregroundStyle(.primary) } icon: { SettingsSymbol(name: "square.and.arrow.up") }
                }
            } else {
                Label("有保存记录后可导出", systemImage: "square.and.arrow.up").foregroundStyle(.secondary)
            }
            Button(role: .destructive) { showClearConfirmation = true } label: {
                Label("清空当前模式数据", systemImage: "trash")
            }
                .accessibilityIdentifier("clear-records")
        }
    }

    @ViewBuilder private var aboutSections: some View {
        Section {
            NavigationLink { CountingRulesView() } label: {
                Label { Text("计数规则与记录范围") } icon: { SettingsSymbol(name: "text.book.closed") }
            }
            LabeledContent("储存方式", value: "仅保存在本机")
        }
        Section {
            HStack {
                Spacer()
                Label("折记 · 仅支持 iPhone Duo", systemImage: "rectangle.split.2x1")
                    .font(.footnote).foregroundStyle(.secondary)
                Spacer()
            }
            .listRowBackground(Color.clear)
        }
    }
}

struct GoalEditorSheet: View {
    let metric: FoldPose

    var body: some View {
        NavigationStack { GoalEditor(metric: metric) }
            .presentationSizing(.form)
            .presentationDragIndicator(.visible)
    }
}

struct GoalEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let metric: FoldPose
    @State private var enabled = false
    @State private var limitText = ""
    @State private var tomorrow = false
    @State private var error: String?
    @State private var initialDraft: Draft?
    @State private var showDiscardConfirmation = false
    @FocusState private var limitFocused: Bool

    private struct Draft: Equatable {
        var enabled: Bool
        var limit: String
        var tomorrow: Bool
    }

    private var hasChanges: Bool {
        guard let initialDraft else { return false }
        return enabled != initialDraft.enabled || (enabled &&
            (limitText != initialDraft.limit || tomorrow != initialDraft.tomorrow))
    }

    private var validLimit: Int? {
        guard let value = Int(limitText), value > 0, value <= 999_999 else { return nil }
        return value
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    PoseSymbol(pose: metric)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("每日\(metric.title)上限").font(.headline)
                        Text("按自己的使用习惯设置")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                Toggle("开启每日上限", isOn: $enabled).accessibilityIdentifier("goal-enabled")
                HStack {
                    Text("每日上限")
                    TextField("输入次数", text: $limitText)
                        .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                        .focused($limitFocused)
                        .monospacedDigit()
                        .accessibilityLabel("每日上限次数")
                        .accessibilityIdentifier("goal-limit")
                    Text("次").foregroundStyle(.secondary)
                }
                .disabled(!enabled)
                Toggle("从明天生效", isOn: $tomorrow).disabled(!enabled)
                Text(enabled
                     ? validLimit.map { "每天\(metric.title)不超过 \($0) 次" } ?? "请输入 1 至 999999 之间的整数"
                     : "开启后可设置每日次数与生效时间")
                    .font(.subheadline).foregroundStyle(.secondary)
                if let error {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "exclamationmark.circle").accessibilityHidden(true)
                        Text(error).accessibilityIdentifier("goal-error")
                    }
                    .font(.footnote).foregroundStyle(.red)
                }
            } header: { Text("\(metric.title)目标") } footer: {
                Text("不预设安全次数，由你决定每日范围。关闭目标会立即生效，已结束日期的目标保持不变。")
            }
            let future = store.archive.goals.first { $0.metric == metric && $0.effectiveFrom > store.archive.calendar.startOfDay(for: Date()) }
            if let future {
                Section("待生效设置") {
                    LabeledContent(future.effectiveFrom.formatted(date: .abbreviated, time: .omitted), value: future.limit.map { "上限 \($0) 次" } ?? "关闭")
                }
            }
        }
        .scrollContentBackground(.hidden).background(Theme.background)
        .navigationTitle("\(metric.title)目标")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(hasChanges)
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                Button("完成") { limitFocused = false }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    if hasChanges { showDiscardConfirmation = true }
                    else { dismiss() }
                }
                .confirmationDialog("放弃未保存的修改？", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                    Button("放弃修改", role: .destructive) { dismiss() }
                    Button("继续编辑", role: .cancel) {}
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    guard !enabled || validLimit != nil else {
                        error = "请输入 1 至 999999 之间的整数次数。"
                        return
                    }
                    if store.setGoal(enabled ? validLimit : nil, for: metric, tomorrow: tomorrow) { dismiss() }
                    else { error = store.storageError ?? "保存失败，请重试。" }
                }
                .fontWeight(.semibold).accessibilityIdentifier("save-goal")
            }
        }
        .onAppear {
            guard initialDraft == nil else { return }
            let current = store.archive.limit(for: metric, on: Date())
            let scheduled = store.archive.goals.first {
                $0.metric == metric && $0.effectiveFrom > store.archive.calendar.startOfDay(for: Date())
            }
            let value = scheduled?.limit ?? current
            enabled = value != nil
            limitText = value.map(String.init) ?? ""
            tomorrow = scheduled != nil || store.archive.goals.contains { $0.metric == metric }
            initialDraft = Draft(enabled: enabled, limit: limitText, tomorrow: tomorrow)
        }
        .onChange(of: limitText) { _, _ in error = nil }
        .onChange(of: enabled) { _, isEnabled in
            if !isEnabled { limitFocused = false }
            error = nil
        }
    }
}

struct CountingRulesView: View {
    var body: some View {
        List {
            Section("怎样计数") {
                rule("折叠", "从半开或全开进入合拢，折叠次数加 1。")
                rule("半开", "从合拢进入半开，并连续停留满 1 秒，半开次数加 1。短暂经过不计。")
                rule("全开", "从合拢或半开进入全开，全开次数加 1。")
                rule("先半开再全开", "半开停留已满 1 秒再全开，两类各计 1 次。半开与全开相加不等于打开手机的次数。")
                rule("从全开收回半开", "只切换当前姿态，不增加半开次数；再次进入全开会增加一次全开。")
            }
            Section("记录范围") {
                Text("首次读取姿态或离开 App 后恢复时，仅建立当前状态，不增加次数。未覆盖时段不会按前后姿态推算。")
                Text("设备记录的后台、锁屏、退出后采集与内外屏切换仍待真机验证。当前只展示已保存次数，不承诺全天无漏记。")
                Text("演示模式与设备记录分别保存，模拟按钮不会修改设备次数。")
            }
            Section("你的数据") {
                Text("次数、时间与目标仅保存在本机，无需账号。导出文件包含这些记录，由你自行选择保存或分享。卸载前请先导出需要保留的数据。")
                Text("体验版提供 JSON 导出，尚未提供导入恢复。")
            }
        }
        .scrollContentBackground(.hidden).background(Theme.background)
        .navigationTitle("计数与记录范围")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func rule(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(detail).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
}
