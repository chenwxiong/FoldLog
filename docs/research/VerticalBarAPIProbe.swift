// SDK type-check probe only; not a running app or verified toolbar layout.
// App-scoped toolbar only; does not meet the requested cross-app system bar.
// Numbers are supplied values, not sensor-derived measurements.
import SwiftUI

@available(iOS 27.1, *)
struct VerticalBarAPIProbeView: View {
    @Environment(\.toolbarVerticalEdge) private var preferredBarEdge

    let closedCount: Int
    let halfOpenCount: Int
    let fullOpenCount: Int

    var body: some View {
        NavigationStack {
            Text(preferredBarEdge == .trailing ? "Preferred edge: trailing" : "Adaptive bar placement")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            // Future app action: show closed-count details.
                        } label: {
                            VStack {
                                Text("折叠")
                                Text(closedCount, format: .number)
                            }
                        }
                        .accessibilityLabel("今日折叠 \(closedCount) 次")
                    }
                    .axisBehavior(.verticalPreferred)

                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("半开 \(halfOpenCount) 次") {}
                            Button("全开 \(fullOpenCount) 次") {}
                        } label: {
                            VStack {
                                Text("展开")
                                Text("半 \(halfOpenCount)")
                                Text("全 \(fullOpenCount)")
                            }
                        }
                        .accessibilityLabel("今日半开 \(halfOpenCount) 次，全开 \(fullOpenCount) 次")
                    }
                    .axisBehavior(.verticalPreferred)
                }
                .toolbarVerticalBehavior(.automatic)
                .toolbarVerticalCompressionBehavior(.prefersToolbarItems)
        }
    }
}
