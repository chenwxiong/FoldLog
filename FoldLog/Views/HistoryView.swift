import SwiftUI
import Charts

struct HistoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var metric: FoldPose = .closed
    @State private var days = 7
    @State private var selectedDay: Date?

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && !dynamicTypeSize.isAccessibilitySize
            TimelineView(.periodic(from: .now, by: 30)) { timeline in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            ModeBadge()
                            Spacer()
                            Picker("时间范围", selection: $days) {
                                Text("近 7 天").tag(7)
                                Text("近 30 天").tag(30)
                            }
                            .pickerStyle(.menu).tint(.primary)
                            .accessibilityIdentifier("history-range")
                        }
                        StorageErrorView()
                        Picker("统计类型", selection: $metric) {
                            ForEach(FoldPose.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented).accessibilityIdentifier("history-metric")
                        if wide {
                            HStack(alignment: .top, spacing: 24) {
                                chartCard(at: timeline.date).frame(maxWidth: .infinity)
                                dailyList(at: timeline.date).frame(maxWidth: .infinity)
                            }
                        } else {
                            chartCard(at: timeline.date)
                            dailyList(at: timeline.date)
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
                .navigationTitle("历史")
                .sheet(item: Binding(
                    get: { selectedDay.map(DaySelection.init) },
                    set: { selectedDay = $0?.date }
                )) { selection in
                    NavigationStack { DayDetailView(date: selection.date) }
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func chartCard(at date: Date) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 18) {
                Label("\(metric.title)记录", systemImage: metric.symbol)
                    .font(.subheadline.weight(.medium))
                if store.archive.events.isEmpty || store.storageError != nil {
                    ContentUnavailableView("还没有记录", systemImage: "chart.bar.xaxis",
                        description: Text(store.mode == .demo
                            ? "在“今日”模拟开合，查看次数变化。"
                            : "收到有效开合变化后，记录会显示在这里。"))
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(rangeCount(at: date))")
                            .font(.system(.largeTitle, design: .rounded).weight(.medium)).monospacedDigit()
                        Text("次").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text("近 \(days) 天已记录").font(.caption).foregroundStyle(.secondary)
                    }
                    chart(at: date)
                    Text("仅表示已记录次数，未记录的日期以“—”显示。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func dailyList(at date: Date) -> some View {
        VStack(spacing: 12) {
            SectionTitle(title: "每日明细", detail: store.archive.timezoneIdentifier)
            Card(padding: 18) {
                VStack(spacing: 0) {
                    ForEach(store.archive.days(endingAt: date, count: days).reversed(), id: \.self) { day in
                        Button { selectedDay = day } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(store.archive.calendar.isDate(day, inSameDayAs: date) ? "今天" : day.formatted(.dateTime.month().day()))
                                        .font(.subheadline.weight(.medium))
                                    Text(day.formatted(.dateTime.weekday(.wide)))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(dayHasRecords(day) && store.storageError == nil ? "\(store.archive.count(metric, on: day)) 次" : "—")
                                    .monospacedDigit().font(.subheadline.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.caption2.weight(.semibold)).foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 10)
                            .frame(minHeight: 52).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(store.archive.calendar.isDate(day, inSameDayAs: date) ? "history-today" : "history-day")
                        if day != store.archive.days(endingAt: date, count: days).first { Divider() }
                    }
                }
            }
        }
    }

    private func rangeCount(at date: Date) -> Int {
        let start = store.archive.days(endingAt: date, count: days).first!
        return store.archive.events.filter { $0.kind == metric && $0.countedAt >= start && $0.countedAt <= date }.count
    }

    private func dayHasRecords(_ day: Date) -> Bool {
        store.archive.events.contains { store.archive.calendar.isDate($0.countedAt, inSameDayAs: day) }
    }

    private func chart(at date: Date) -> some View {
        let chartDays = store.archive.days(endingAt: date, count: days)
        let end = store.archive.calendar.date(byAdding: .day, value: 1, to: chartDays.last!)!
        let step = days == 7 ? 2 : 7
        let axisDates = chartDays.enumerated().compactMap { index, day -> Date? in
            guard index.isMultiple(of: step) else { return nil }
            return store.archive.calendar.date(byAdding: .hour, value: 12, to: day)
        }
        // Each bar covers a whole calendar day, including just after midnight.
        return Chart(chartDays, id: \.self) { day in
            if dayHasRecords(day) {
                BarMark(x: .value("日期", day, unit: .day), y: .value("已记录次数", store.archive.count(metric, on: day)))
                    .foregroundStyle(Theme.accent).cornerRadius(5)
                    .accessibilityLabel(day.formatted(.dateTime.month().day()))
                    .accessibilityValue("\(store.archive.count(metric, on: day)) 次，部分记录")
            }
        }
        .chartXScale(domain: chartDays.first!...end)
        .chartXAxis {
            AxisMarks(values: axisDates) { value in
                AxisValueLabel(centered: false, anchor: value.index == axisDates.count - 1 ? .topTrailing : .top) {
                    if let day = value.as(Date.self) {
                        Text("\(store.archive.calendar.component(.month, from: day))/\(store.archive.calendar.component(.day, from: day))")
                            .fixedSize()
                    }
                }
            }
        }
        .environment(\.calendar, store.archive.calendar)
        .environment(\.timeZone, store.archive.calendar.timeZone)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                AxisValueLabel()
            }
        }
        .frame(height: 170)
    }
}

private struct DaySelection: Identifiable {
    let date: Date
    var id: Date { date }
}

struct DayDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let date: Date

    var body: some View {
        List {
            Section {
                ForEach(FoldPose.allCases) { metric in
                    LabeledContent {
                        Text(store.storageError == nil ? "\(store.archive.count(metric, on: date)) 次" : "—")
                            .monospacedDigit()
                    } label: {
                        Label(metric.title, systemImage: metric.symbol)
                    }
                }
            } header: { Text("已记录次数") } footer: {
                Text("仅表示已有记录，不能据此判断当天没有开合。")
            }
            Section("当日目标") {
                ForEach(FoldPose.allCases) { metric in
                    LabeledContent(metric.title, value: store.archive.limit(for: metric, on: date).map { "上限 \($0) 次" } ?? "未设置")
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("day-goal-\(metric.rawValue)")
                }
            }
            Section("事件明细") {
                let events = store.archive.events.filter { store.archive.calendar.isDate($0.countedAt, inSameDayAs: date) }.reversed()
                if events.isEmpty {
                    Label("当日没有已保存事件", systemImage: "clock").foregroundStyle(.secondary)
                }
                ForEach(Array(events)) { event in
                    LabeledContent(event.kind.title, value: event.countedAt.formatted(.dateTime.hour().minute().second()))
                        .monospacedDigit()
                }
            }
        }
        .scrollContentBackground(.hidden).background(Theme.background)
        .navigationTitle(date.formatted(.dateTime.month().day()))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
    }
}
