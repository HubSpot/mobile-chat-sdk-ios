// HubspotConfig.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation

/// Enum used during configuration. The default is production - if in doubt choose production
public enum HubspotEnvironment: String, Codable, CustomStringConvertible {
    /// QA environment , mostly for internal use
    case qa
    /// Production environment, the most commonly used environment
    case production = "prod"

    public var description: String {
        switch self {
        case .production:
            return "Production"
        case .qa:
            return "QA"
        }
    }
}

/// Encapsulates some of the logic around hublets, as some are treated differently than others. Right now we know of only 2, but this might expand in the future?
struct Hublet {
    /// This is the default(?) hublet, it uses just plain sub domain
    let defaultUS = "na1"

    let id: String

    /// The format of subdomain varies between hublets
    var appsSubDomain: String {
        if id.lowercased() == defaultUS {
            return "app"
        } else {
            // other hublets like eu1 have hublet in the subdomain
            return "app-\(id)"
        }
    }
}

/// Errors relating to setting up SDK
public enum HubspotConfigError: LocalizedError {
    /// Missing config file, or missing value within - if this error occurs, make sure hubspot info file is bundled in app, and that  the manager configure method  ``HubspotManager/configure()`` has been called .
    case missingConfiguration

    /// Chat flow is needed to correctly show a chat
    case missingChatFlow

    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Couldn't find a configuration at the expected path \(HubspotConfig.defaultConfigFileName)"
        case .missingChatFlow:
            return "No chat flow provided, and no default found"
        }
    }

    public var failureReason: String? {
        switch self {
        case .missingConfiguration:
            return "Couldn't find a configuration at the expected path \(HubspotConfig.defaultConfigFileName)"
        case .missingChatFlow:
            return "No chat flow provided, and no default found"
        }
    }
}

/// This struct for decoding the config file bundled in app - the config file contains the required pieces of info needed to connect to the correct hubspot endponts like that , account specific info like portal id and hublet
///
/// By default, the SDK will initialise using a known file path, Hubspot-Info.plist
///
public struct HubspotConfig: Codable {
    /// This is the default, assumed filename for the plist bunded in app containing the config values
    public static let defaultConfigFileName: String = "Hubspot-Info.plist"

    /// The hubspot environment to use
    public let environment: HubspotEnvironment

    /// The hublet the portal is in, for example "na1" or "eu1"
    public let hublet: String

    /// The unique id for the customers hubspot portal
    public let portalId: String

    /// The default chat flow value to use if not specified when creating a chat view
    public let defaultChatFlow: String?
}
