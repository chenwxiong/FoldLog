import WidgetKit

@MainActor
enum WidgetSync {
    static func publish(_ snapshot: WidgetSnapshot) throws {
        guard let repository = WidgetSnapshotRepository.shared else {
            throw ArchiveError.incompatible
        }
        try repository.save(snapshot)
        WidgetCenter.shared.reloadTimelines(ofKind: "FoldLog.Count")
    }
}
