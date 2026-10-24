import SwiftUI

@main
struct FoldLogApp: App {
    @State private var store = AppStore()
    @AppStorage("appearance") private var appearance = "system"

    var body: some Scene {
        WindowGroup {
            Group {
                if DeviceSupport.isSupported || DeviceSupport.isDesignPreview {
                    RootView()
                } else {
                    UnsupportedDeviceView()
                }
            }
                .environment(store)
                .tint(Theme.accent)
                .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
                .modifier(UIPreviewConfiguration())
        }
    }
}

private struct UIPreviewConfiguration: ViewModifier {
    func body(content: Content) -> some View {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            if ProcessInfo.processInfo.arguments.contains("--large-text") {
                content.dynamicTypeSize(.accessibility5).preferredColorScheme(.dark)
            } else if ProcessInfo.processInfo.arguments.contains("--dark") {
                content.preferredColorScheme(.dark)
            } else { content.preferredColorScheme(.light) }
        } else { content }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection = 0
    @State private var widgetGoal: FoldPose?

    var body: some View {
        TabView(selection: $selection) {
            Tab("今日", systemImage: "square.grid.2x2.fill", value: 0) {
                NavigationStack { TodayView() }
            }
            Tab("历史", systemImage: "chart.bar.xaxis", value: 1) {
                NavigationStack { HistoryView() }
            }
            Tab("设置", systemImage: "gearshape.fill", value: 2) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .modifier(HingeInputModifier())
        .onOpenURL { url in
            guard let destination = WidgetDestination(url: url) else { return }
            selection = 0
            widgetGoal = destination == .goal ? .closed : nil
            store.publishWidgets()
        }
        .sheet(item: $widgetGoal) { metric in
            GoalEditorSheet(metric: metric)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            store.setActive(phase == .active)
        }
    }
}

private struct HingeInputModifier: ViewModifier {
    @Environment(AppStore.self) private var store

    func body(content: Content) -> some View {
        if #available(iOS 27.1, *) {
            content.onHingeChange(isEnabled: store.mode == .device && store.isActive) { _, context in
                guard let hinge = context.hinge else {
                    store.receiveHinge(nil)
                    return
                }
                switch hinge.status {
                case .closed: store.receiveHinge(.closed)
                case .partiallyOpen: store.receiveHinge(.halfOpen)
                case .fullyOpen: store.receiveHinge(.fullyOpen)
                default: store.receiveHinge(nil)
                }
            }
        } else { content }
    }
}
