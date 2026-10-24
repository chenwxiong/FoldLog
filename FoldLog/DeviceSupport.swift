import SwiftUI
import UIKit
import Darwin

enum DeviceSupport {
    static var isDesignPreview: Bool {
        #if DEBUG && targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        return !arguments.contains("--check-device-support") &&
            (arguments.contains("--design-preview") || arguments.contains("--ui-testing"))
        #else
        return false
        #endif
    }

    @MainActor static var isSupported: Bool {
        DeviceSupportPolicy.supports(modelIdentifier: modelIdentifier,
            isPhone: UIDevice.current.userInterfaceIdiom == .phone && !ProcessInfo.processInfo.isiOSAppOnMac,
            systemVersion: ProcessInfo.processInfo.operatingSystemVersion)
    }

    private static var modelIdentifier: String {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "unknown"
        #else
        var info = utsname()
        guard uname(&info) == 0 else { return "unknown" }
        return withUnsafeBytes(of: &info.machine) { bytes in
            String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
        #endif
    }
}

struct UnsupportedDeviceView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("BrandMark")
                    .resizable().scaledToFit().frame(width: 112, height: 112)
                    .background(Color(.sRGB, red: 0.9451, green: 0.9137, blue: 0.8627, opacity: 1), in: RoundedRectangle(cornerRadius: 26))
                    .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text("仅支持 iPhone Duo")
                        .font(.title2.weight(.semibold))
                        .accessibilityIdentifier("unsupported-device-title")
                    Text("折记专为 iPhone Duo 的开合记录设计。\n请在 iPhone Duo 上使用，并更新至 iOS 27.1 或更新版本。")
                        .font(.body).foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 440)
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .defaultScrollAnchor(.center)
        .background(Theme.background)
    }
}
