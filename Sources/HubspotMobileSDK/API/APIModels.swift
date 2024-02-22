// APIModels.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation

/// This is the body of the api request for sending chat properties,  to help with JSON encoding.
struct ChatPropertyMetadataRequest: Encodable {
    /// The visitor id token , provided by the app itself. This is the token obtained from app backend from hubspot api
    let visitorToken: String?

    /// The email provided with the visitor token itself.
    let email: String?

    /// dictionary of arbitary key and values to send to the api - see ``ChatPropertyKey``
    /// - seeAlso: ``ChatPropertyKey``
    let metadata: [String: String]
}

/// Model used for serialisation when creating a visitor token
struct CreateVisitorTokenRequest: Codable {
    let email: String
    let firstName: String
    let lastName: String
}

/// Model for serialising post body of adding a device token
struct StoreDeviceTokenRequest: Encodable {
    let devicePushToken: String
    let platform = "ios"
    // Do we need user id here?

    init(devicePushToken: Data) {
        self.devicePushToken = devicePushToken.toHexString()
    }
}

/// Model used for deserialising the create visitor token response
struct CreateVisitorTokenResponse: Codable {
    let token: String
}

extension Data {
    /// Used to encode push tokens
    /// - Returns: The data in hex format, lowercase
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
