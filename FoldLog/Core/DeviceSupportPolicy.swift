import Foundation

enum DeviceSupportPolicy {
    // Xcode 27.1's iPhone Duo.simdevicetype lists this represented model.
    // Revalidate this allowlist against production hardware before distribution.
    static let duoModelIdentifiers: Set<String> = ["iPhone19,4"]
    static let minimumOS = OperatingSystemVersion(majorVersion: 27, minorVersion: 1, patchVersion: 0)

    static func supports(modelIdentifier: String, isPhone: Bool, systemVersion: OperatingSystemVersion) -> Bool {
        guard isPhone, duoModelIdentifiers.contains(modelIdentifier) else { return false }
        return systemVersion.majorVersion > minimumOS.majorVersion ||
            (systemVersion.majorVersion == minimumOS.majorVersion && systemVersion.minorVersion >= minimumOS.minorVersion)
    }
}
