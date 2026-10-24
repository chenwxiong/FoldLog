import XCTest
@testable import FoldLogCore

final class DeviceSupportTests: XCTestCase {
    func testOnlyDuoWithHingeOSIsSupported() {
        let current = OperatingSystemVersion(majorVersion: 27, minorVersion: 1, patchVersion: 0)
        XCTAssertTrue(DeviceSupportPolicy.supports(modelIdentifier: "iPhone19,4", isPhone: true, systemVersion: current))
        for model in ["iPhone18,1", "iPad16,3", "arm64", "", "iPhone19,5"] {
            XCTAssertFalse(DeviceSupportPolicy.supports(modelIdentifier: model, isPhone: true, systemVersion: current))
        }
        XCTAssertFalse(DeviceSupportPolicy.supports(modelIdentifier: "iPhone19,4", isPhone: false, systemVersion: current))
        XCTAssertFalse(DeviceSupportPolicy.supports(modelIdentifier: "iPhone19,4", isPhone: true,
            systemVersion: .init(majorVersion: 27, minorVersion: 0, patchVersion: 9)))
        XCTAssertTrue(DeviceSupportPolicy.supports(modelIdentifier: "iPhone19,4", isPhone: true,
            systemVersion: .init(majorVersion: 28, minorVersion: 0, patchVersion: 0)))
    }
}
