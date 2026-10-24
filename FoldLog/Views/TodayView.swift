import SwiftUI

struct TodayView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var editingGoal: FoldPose?
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 76

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && !dynamicTypeSize.isAccessibilitySize
            TimelineView(.periodic(from: .now, by: 30)) { timeline in
                ScrollView {
                    VStack(spacing: 20) {
                        heading(at: timeline.date)
                        StorageErrorView()
                        if wide {
                            HStack(alignment: .top, spacing: 24) {
                                VStack(spacing: 16) {
                                    hero(at: timeline.date)
                                    dailySummary(at: timeline.date)
                                }
                                .frame(maxWidth: .infinity)
                                VStack(spacing: 24) {
                                    goals(at: timeline.date)
                                    if store.mode == .demo { simulationControls }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            hero(at: timeline.date)
                            dailySummary(at: timeline.date)
                            if store.mode == .demo { simulationControls }
                            goals(at: timeline.date)
                        }
                        RecordScopeNote()
                    }
                    .frame(maxWidth: wide ? Theme.contentWidth : 580)
                    .padding(.horizontal, wide ? 28 : 20)
                    .padding(.top, 4).padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                }
                .safeAreaPadding(.bottom, 12)
                .background(Theme.background)
                .navigationTitle("今日")
                .sheet(item: $editingGoal) { metric in
                    GoalEditorSheet(metric: metric)
                }
            }
        }
    }

    private func heading(at date: Date) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                Text(date.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 12)
                ModeBadge()
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(date.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.subheadline).foregroundStyle(.secondary)
                ModeBadge()
            }
        }
    }

    private func hero(at date: Date) -> some View {
        Card(padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(store.pose.map { "当前\($0.stateTitle) · \($0 == .closed ? "外屏" : "内屏")预览" } ?? "等待有效姿态")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("今日\(store.visibleMetric.title)").font(.headline)
                    }
                    Spacer(minLength: 12)
                    PoseSymbol(pose: store.visibleMetric)
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(store.storageError == nil ? "\(store.archive.count(store.visibleMetric, on: date))" : "—")
                        .font(.system(size: numberSize, weight: .medium, design: .rounded))
                        .minimumScaleFactor(0.4).lineLimit(1).monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: store.archive.count(store.visibleMetric, on: date))
                        .accessibilityIdentifier("hero-count")
                    Text("次").font(.title3).foregroundStyle(.secondary)
                }
                Label(store.storageError == nil ? "累计已记录 \(store.archive.count(store.visibleMetric)) 次" : "累计暂不可用",
                      systemImage: "clock.arrow.circlepath")
                    .font(.subheadline).foregroundStyle(.secondary)
                Divider()
                Label(statusText, systemImage: store.isHalfPending ? "hourglass" : store.pose == nil ? "pause.circle" : "checkmark.circle")
                    .font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("recording-status")
            }
        }
    }

    private var statusText: String {
        if store.storageError != nil { return "记录已暂停，请检查储存状态" }
        if store.isHalfPending { return "半开确认中 · 连续停留满 1 秒后计入" }
        if store.mode == .demo { return "通过下方按钮体验开合计数" }
        if !store.canReadHinge { return "当前系统不支持铰链读取，可切换演示模式" }
        if store.pose == nil { return "尚未收到铰链数据，可切换演示模式" }
        return "前台记录中 · 全天采集尚未验证"
    }

    private func dailySummary(at date: Date) -> some View {
        Card(padding: 16) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 16) {
                    ForEach(FoldPose.allCases) { metric in
                        HStack {
                            Label(metric.title, systemImage: metric.symbol).foregroundStyle(.secondary)
                            Spacer()
                            summaryCount(metric, date: date)
                        }
                        if metric != FoldPose.allCases.last { Divider() }
                    }
                }
            } else {
                HStack(spacing: 0) {
                    ForEach(FoldPose.allCases) { metric in
                        VStack(spacing: 8) {
                            Label(metric.title, systemImage: metric.symbol)
                                .font(.caption).foregroundStyle(.secondary)
                            summaryCount(metric, date: date)
                        }
                        .frame(maxWidth: .infinity)
                        if metric != FoldPose.allCases.last { Divider().frame(height: 34) }
                    }
                }
            }
        }
        .accessibilityLabel("今日开合一览")
    }

    private func summaryCount(_ metric: FoldPose, date: Date) -> some View {
        Text(store.storageError == nil ? "\(store.archive.count(metric, on: date)) 次" : "—")
            .font(.headline).monospacedDigit()
            .accessibilityIdentifier("summary-\(metric.rawValue)")
    }

    private func goals(at date: Date) -> some View {
        VStack(spacing: 12) {
            SectionTitle(title: store.pose == .closed ? "每日展开目标" : "每日折叠目标", detail: "自定上限")
            Card(padding: 18) {
                VStack(spacing: 14) {
                    ForEach(goalMetrics) { metric in
                        GoalSummaryRow(metric: metric, date: date) { editingGoal = metric }
                        if metric != goalMetrics.last { Divider() }
                    }
                }
            }
        }
    }

    private var goalMetrics: [FoldPose] {
        store.pose == .closed ? [.halfOpen, .fullyOpen] : [.closed]
    }

    private var simulationControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "模拟开合", detail: "仅演示")
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) { poseButtons }
            } else {
                HStack(spacing: 10) { poseButtons }
            }
            Text("半开连续停留满 1 秒才计数，短暂经过不计入。")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var poseButtons: some View {
        ForEach(FoldPose.allCases) { pose in
            Button { store.simulate(pose) } label: {
                Label(pose.stateTitle, systemImage: pose.symbol)
                    .font(.subheadline.weight(.medium))
                    .symbolVariant(store.pose == pose ? .fill : .none)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .tint(store.pose == pose ? Theme.accent : Color(uiColor: .secondaryLabel))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(store.pose == pose ? Theme.accent.opacity(0.5) : .clear, lineWidth: 1)
                    .allowsHitTesting(false)
            }
            .accessibilityAddTraits(store.pose == pose ? .isSelected : [])
            .accessibilityIdentifier("simulate-\(pose.rawValue)")
            .disabled(store.storageError != nil)
        }
    }
}

struct GoalSummaryRow: View {
    @Environment(AppStore.self) private var store
    let metric: FoldPose
    let date: Date
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: metric.symbol).font(.title3).foregroundStyle(Theme.accent)
                    .frame(width: 24).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.title).font(.subheadline.weight(.semibold))
                    Text(detail).font(.footnote).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                Button(action: edit) {
                    Text(store.archive.limit(for: metric, on: date) == nil ? "设置" : "修改")
                        .font(.subheadline.weight(.medium))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("设置\(metric.title)目标")
            }
            if let limit = store.archive.limit(for: metric, on: date), store.storageError == nil {
                let count = store.archive.count(metric, on: date)
                ProgressView(value: min(Double(count) / Double(limit), 1))
                    .tint(Theme.accent)
                    .accessibilityLabel("\(metric.title)上限使用情况")
                    .accessibilityValue("已记录\(count)次，上限\(limit)次")
                if count >= limit {
                    Label(count == limit ? "已达到自定上限" : "已超过自定上限 \(count - limit) 次", systemImage: "flag")
                        .font(.footnote).foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var detail: String {
        guard store.storageError == nil else { return "目标暂不可用" }
        guard let limit = store.archive.limit(for: metric, on: date) else { return "未设置每日上限" }
        return "已记录 \(store.archive.count(metric, on: date)) / 上限 \(limit) 次"
    }
}
