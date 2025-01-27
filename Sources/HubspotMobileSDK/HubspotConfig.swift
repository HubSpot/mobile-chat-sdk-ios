// HubspotConfig.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation

/// Enum used during configuration. The default is production - if in doubt choose production
public enum HubspotEnvironment: String, Codable, CustomStringConvertible, Sendable {
    /// QA environment , mostly for internal use
    case qa
    /// Production environment, the most commonly used environment
    case production = "prod"

    /// Display friendly name for the environment
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
    let environment: HubspotEnvironment

    /// The format of subdomain varies between hublets
    private var appsSubDomain: String {
        let id = id.lowercased()
        if id == defaultUS {
            return "app"
        } else {
            // other hublets like eu1 have hublet in the subdomain
            return "app-\(id)"
        }
    }

    private var appsDomain: String {
        // Right now, qa env has its own domain
        switch environment {
        case .production:
            return "hubspot.com"
        case .qa:
            return "hubspotqa.com"
        }
    }

    /// The format of subdomain varies between hublets
    private var apiSubDomain: String {
        let id = id.lowercased()
        if id == defaultUS {
            return "api"
        } else {
            // other hublets like eu1 have hublet in the subdomain
            return "api-\(id)"
        }
    }

    private var apiDomain: String {
        // Right now, qa env has its own domain
        switch environment {
        case .production:
            return "hubapi.com"
        case .qa:
            return "hubapiqa.com"
        }
    }

    /// hostname used for the embedded chat page
    var hostname: String {
        return appsSubDomain + "." + appsDomain
    }

    /// hostname used for api calls
    var apiHostname: String {
        return apiSubDomain + "." + apiDomain
    }

    /// base url for api calls - append path before using
    var apiURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = apiHostname
        guard let url = components.url else {
            fatalError("Unable to build URL from configuration")
        }
        return url
    }
}

/// Errors relating to setting up SDK
public enum HubspotConfigError: LocalizedError, Sendable {
    /// Missing config file, or missing value within - if this error occurs, make sure hubspot info file is bundled in app, and that  the manager configure method  ``HubspotManager/configure()-swift.type.method`` has been called .
    case missingConfiguration

    /// Chat flow is needed to correctly show a chat
    case missingChatFlow

    /// Description of the error and reason for failure, same as ``failureReason`` currently.
    public var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "Couldn't find a configuration at the expected path \(HubspotConfig.defaultConfigFileName)"
        case .missingChatFlow:
            return "No chat flow provided, and no default found"
        }
    }
    /// Description of the error and reason for failure, same as ``errorDescription`` currently.
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
public struct HubspotConfig: Codable, Sendable {
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
