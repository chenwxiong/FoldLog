// SDK type-check probe only. This is not a running app or a fold counter.
// Availability and background delivery must be validated on iPhone Duo.
import SwiftUI
import UIKit

@available(iOS 27.1, *)
struct HingeAPIProbeView: View {
    @State private var angleDegrees: Double?

    var body: some View {
        Text(angleDegrees.map { "Angle: \($0)" } ?? "Hinge unavailable")
            .onHingeChange { _, newContext in
                guard let hinge = newContext.hinge else {
                    angleDegrees = nil
                    return
                }
                angleDegrees = hinge.angle.degrees
                let isClosed = hinge.status == .closed
                _ = isClosed
            }
    }
}

@available(iOS 27.1, *)
@MainActor
func attachHingeProbe(to view: UIView) {
    let interaction = UIHingeInteraction { _, update in
        guard let hinge = update.hinge else { return }
        let radians = hinge.angle
        switch hinge.status {
        case .unknown, .closed, .partiallyOpen, .fullyOpen:
            _ = radians
        @unknown default:
            break
        }
    }
    view.addInteraction(interaction)
}
