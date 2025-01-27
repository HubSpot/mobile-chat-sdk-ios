// HubspotMobileSDKTests.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import XCTest

@testable import HubspotMobileSDK

@MainActor
final class HubspotMobileSDKTests: XCTestCase {
    func testDeviceModelReading() throws {
        let manager = HubspotManager()
        let value = manager.deviceModel()
        XCTAssertFalse(value.isEmpty)
    }
}

@MainActor
final class HubspotHubletTests: XCTestCase {
    func testNA1Hublet() throws {
        let hublet = Hublet(id: "na1", environment: .production)

        XCTAssertEqual(hublet.hostname, "app.hubspot.com")
        XCTAssertEqual(hublet.apiURL.absoluteString, "https://api.hubapi.com")

        let hubletQA = Hublet(id: "NA1", environment: .qa)
        XCTAssertEqual(hubletQA.hostname, "app.hubspotqa.com")
        XCTAssertEqual(hubletQA.apiURL.absoluteString, "https://api.hubapiqa.com")
    }

    func testEU1Hublet() throws {
        let hublet = Hublet(id: "eu1", environment: .production)
        XCTAssertEqual(hublet.hostname, "app-eu1.hubspot.com")
        XCTAssertEqual(hublet.apiURL.absoluteString, "https://api-eu1.hubapi.com")

        let hubletQA = Hublet(id: "EU1", environment: .qa)
        XCTAssertEqual(hubletQA.hostname, "app-eu1.hubspotqa.com")
        XCTAssertEqual(hubletQA.apiURL.absoluteString, "https://api-eu1.hubapiqa.com")
    }
}
