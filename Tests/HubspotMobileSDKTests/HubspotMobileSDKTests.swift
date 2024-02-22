import XCTest
@testable import HubspotMobileSDK

final class HubspotMobileSDKTests: XCTestCase {
    func testDeviceModelReading() throws {
        let manager = HubspotManager()
        let value = manager.deviceModel()
        XCTAssertFalse(value.isEmpty)
    }
}
