import SwiftUI
import Observation

@MainActor @Observable
final class AppStore {
    private(set) var archive: RecordArchive
    private(set) var mode: InputMode
    private(set) var pose: FoldPose?
    private(set) var isActive = false
    private(set) var isHalfPending = false
    private(set) var storageError: String?
    private(set) var lastRecordedAt: Date?
    private(set) var widgetSyncError: String?
    private(set) var widgetUpdatedAt: Date?
    private var engine = CountingEngine()
    private var halfTask: Task<Void, Never>?
    private let repository: ArchiveRepository
    private let isTesting: Bool
    private let widgetsEnabled: Bool
    private var archiveReadable = true
    private var simulatedPose: FoldPose = .closed

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let testing = arguments.contains("--ui-testing")
        isTesting = testing
        widgetsEnabled = !testing || arguments.contains("--widget-integration-testing")
        let directory = URL.applicationSupportDirectory.appendingPathComponent(testing ? "FoldLogUITests" : "FoldLog")
        repository = ArchiveRepository(directory: directory)
        if testing && arguments.contains("--reset-data") {
            try? FileManager.default.removeItem(at: directory)
        }
        let defaultMode: InputMode = testing || DeviceSupport.isDesignPreview ? .demo : .device
        let initialMode = testing ? InputMode.demo :
            InputMode(rawValue: UserDefaults.standard.string(forKey: "inputMode") ?? defaultMode.rawValue) ?? defaultMode
        mode = initialMode
        archive = RecordArchive(mode: initialMode)
        pose = initialMode == .demo ? .closed : nil
        do { archive = try repository.load(initialMode) }
        catch {
            archiveReadable = false
            storageError = "无法读取本地记录。原文件已保留，记录已暂停。"
        }
        publishWidgets()
    }

    var visibleMetric: FoldPose { pose ?? .closed }
    var canReadHinge: Bool {
        DeviceSupport.isSupported
    }

    func setActive(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        stopSession()
        if active && mode == .demo { receive(simulatedPose) }
        if mode == .device { pose = nil }
        publishWidgets()
    }

    func changeMode(_ value: InputMode) {
        guard mode != value else { return }
        stopSession()
        mode = value
        if !isTesting { UserDefaults.standard.set(value.rawValue, forKey: "inputMode") }
        storageError = nil
        archiveReadable = true
        archive = RecordArchive(mode: value)
        lastRecordedAt = nil
        do { archive = try repository.load(value) }
        catch {
            archiveReadable = false
            storageError = "无法读取本地记录。原文件已保留，记录已暂停。"
        }
        pose = value == .demo ? simulatedPose : nil
        if isActive && value == .demo { receive(simulatedPose) }
        publishWidgets()
    }

    func simulate(_ value: FoldPose) {
        guard mode == .demo else { return }
        simulatedPose = value
        receive(value)
    }

    func receiveHinge(_ value: FoldPose?) {
        guard mode == .device else { return }
        receive(value)
    }

    private func receive(_ value: FoldPose?) {
        guard isActive, storageError == nil else { return }
        pose = value
        let events = engine.observe(value, at: ProcessInfo.processInfo.systemUptime, date: Date())
        commit(events)
        scheduleHalfConfirmation()
    }

    private func scheduleHalfConfirmation() {
        // Repeated samples keep the original deadline, rather than starting another second.
        halfTask?.cancel()
        halfTask = nil
        guard storageError == nil, let deadline = engine.halfOpenDeadline else {
            isHalfPending = false
            return
        }
        isHalfPending = true
        halfTask = Task { [weak self] in
            let delay = max(0, deadline - ProcessInfo.processInfo.systemUptime)
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
            guard let self, self.isActive, !Task.isCancelled else { return }
            self.commit(self.engine.advance(to: ProcessInfo.processInfo.systemUptime))
            self.isHalfPending = self.engine.halfOpenDeadline != nil
        }
    }

    private func commit(_ events: [FoldEvent]) {
        guard !events.isEmpty else { return }
        var next = archive
        next.events.append(contentsOf: events)
        if save(next) { lastRecordedAt = events.last?.countedAt }
    }

    @discardableResult
    private func save(_ next: RecordArchive) -> Bool {
        do {
            try repository.save(next)
            archive = next
            archiveReadable = true
            publishWidgets()
            return true
        } catch {
            storageError = "本次变化未保存，记录已暂停。请检查储存空间后重试。"
            stopSession()
            publishWidgets()
            return false
        }
    }

    func setGoal(_ limit: Int?, for metric: FoldPose, tomorrow: Bool) -> Bool {
        guard storageError == nil else { return false }
        var next = archive
        let date = tomorrow && limit != nil ? next.calendar.date(byAdding: .day, value: 1, to: Date())! : Date()
        next.setLimit(limit, for: metric, from: date)
        return save(next)
    }

    func retry() {
        do {
            archive = try repository.load(mode)
            storageError = nil
            archiveReadable = true
            stopSession()
            if isActive && mode == .demo { receive(simulatedPose) }
        } catch {
            archiveReadable = false
            storageError = "仍无法读取记录。原文件已保留，请稍后重试。"
        }
        publishWidgets()
    }

    func clearCurrentRecords() {
        stopSession()
        let next = RecordArchive(mode: mode)
        if save(next) {
            storageError = nil
            lastRecordedAt = nil
            if mode == .demo && isActive { receive(simulatedPose) }
            else { pose = nil }
            publishWidgets()
        }
    }

    func publishWidgets() {
        guard widgetsEnabled else { return }
        let now = Date()
        do {
            try WidgetSync.publish(WidgetSnapshot(archive: archive, at: now,
                readable: archiveReadable, recordingPaused: storageError != nil))
            widgetUpdatedAt = now
            widgetSyncError = nil
        } catch {
            widgetSyncError = "小组件暂未同步。请稍后重试；App 内记录已保留。"
        }
    }

    func widgetValue(at date: Date) -> WidgetValue {
        var value = WidgetSnapshot(archive: archive, at: date, readable: archiveReadable,
                                   recordingPaused: storageError != nil).value(at: date)
        value.updatedAt = widgetUpdatedAt
        return value
    }

    func exportURL() -> URL? {
        guard storageError == nil else { return nil }
        let url = repository.url(for: mode)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func stopSession() {
        halfTask?.cancel()
        halfTask = nil
        engine.invalidate()
        isHalfPending = false
    }
}
