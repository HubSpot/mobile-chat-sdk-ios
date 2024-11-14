// HubspotManager.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Combine
import Foundation
import OSLog
import SwiftUI
import UserNotifications

/// Logger is created in multiple places, so this is a helper for that to avoid repeating values
private func createDefaultHubspotLogger() -> Logger {
    return Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hubspot.mobilesdk", category: "HubspotSDK")
}

/// The main interface for the Hubspot mobile SDK.
///
/// Call ``configure()-swift.type.method`` before using. Chat sessions can be started & shown  using ``HubspotChatView``
///
/// Use ``setUserIdentity(identityToken:email:)`` to optionally identify users with server side generated tokens.
///
/// Use ``setChatProperties(data:)`` to include additional data , including custom key value pairs that are useful during chat sessions.
///
/// For more setup instructions, see <doc:GettingStarted>
///
///
@MainActor
public class HubspotManager: NSObject, ObservableObject {
    /// Shared instance that can be used app wide, instead of creating an managing own instance.
    /// If not using this instance, and instead managing your own instance, make sure to pass your instance as an argument to the ``HubspotChatView`` or other components.
    public static let shared = HubspotManager()

    /// The hublet to use, if configured
    public private(set) var hublet: String?

    /// The portalId to use, if configured
    public private(set) var portalId: String?

    /// The default chat flow, if configured
    public private(set) var defaultChatFlow: String?

    /// the currently configured environment
    public private(set) var environment: HubspotEnvironment = .production

    /// The identity token currently set for the user
    /// - seeAlso: ``setUserIdentity(identityToken:email:)``
    public private(set) var userIdentityToken: String?

    /// The email address currently set for the user
    /// - seeAlso: ``setUserIdentity(identityToken:email:)``
    public private(set) var userEmailAddress: String?

    /// The push token - this should be set by the app whenever it has access to the token.
    /// - seeAlso: ``setPushToken(apnsPushToken:)``
    public private(set) var pushToken: Data?

    /// We might not be in a position to send the token immediately, so we need to track if we need to send it later, after configuration
    private var pushTokenSyncState: DeviceTokenSyncState = .notSent
    private var sendPushTokenTask: Task<Void, Never>?

    /// This is the collection of user properties that are sent to Hubspot on opening chat sessions. set with ``setChatProperties(data:)``
    /// - seeAlso: ChatPropertyKey
    public private(set) var chatProperties: [String: String] = [:]

    /// Callback triggered when user opens a hubspot message. Only triggered when manager is acting as the UNNotificationDelegate, or notifications are forwarded to the ``userNotificationCenter(_:didReceive:withCompletionHandler:)`` method on this manager instance.
    public var newMessageCallback: (PushNotificationChatData) -> Void = { _ in }

    /// Publisher triggered when user opens a hubspot message. Only triggered when manager is acting as the UNNotificationDelegate, or notifications are forwarded to the ``userNotificationCenter(_:didReceive:withCompletionHandler:)`` method on this manager instance.
    public private(set) var newMessage: PassthroughSubject<PushNotificationChatData, Never> = PassthroughSubject()

    /// The logger used by the SDK. to disable logging set to the disabled OSLog with  `Logger(.disabled)`, or set a custom Logger with a preferred subsystem and category
    public var logger = createDefaultHubspotLogger() {
        didSet {
            api.logger = logger
        }
    }

    private var hubletModel: Hublet? {
        guard let hublet
        else {
            return nil
        }

        return Hublet(id: hublet, environment: environment)
    }

    /// Record if we turned on battery monitoring. If we didn't turn it on , we might not want to turn it off again.
    var didWeEnableBatterMonitoring: Bool = false
    /// Record if we turned on origentation monitoring. If we didn't turn it on , we might not want to turn it off again.
    var didWeEnableOrientationMonitoring: Bool = false

    private var api: HubspotAPI

    /// Use the provided config values, applied to the shared instance ``shared``
    /// - Parameters:
    ///   - portalId: Your portal id - you can find it from your hubspot account page
    ///   - hublet: Hublet name , typically "na1" or "eu1"
    ///   - defaultChatFlow: The default chat flow to use if none is specified per chat view
    ///   - environment: the environment to use
    public static func configure(portalId: String,
                                 hublet: String,
                                 defaultChatFlow: String?,
                                 environment: HubspotEnvironment = .production)
    {
        shared.configure(portalId: portalId,
                         hublet: hublet,
                         defaultChatFlow: defaultChatFlow,
                         environment: environment)
    }

    /// Load SDK configuration from bundled config file. Note this only applies to the shared instance ``shared`` , if you intend to create a new instance of `HubspotManager`, you should use the non static version on that instance , ``configure()-swift.method``
    ///
    /// throws ``HubspotConfigError`` if config file isnt as expected
    public static func configure() throws {
        try shared.configure()
    }

    /// Create unconfigured SDK instance - not currently set public, use shared instance for now.
    override init() {
        api = HubspotAPI(logger: logger)
    }

    /// Configure this SDK instance with the bundled `Hubspot-Info.plist`  config file from the main bundle.
    ///  - throws: `HubspotConfigError.missingConfiguration` thrown if config file cannot be found in the bundle, or if it contains missing required items.
    public func configure() throws {
        guard let plistUrl = Bundle.main.url(forResource: HubspotConfig.defaultConfigFileName, withExtension: nil) else {
            throw HubspotConfigError.missingConfiguration
        }
        let plistData = try Data(contentsOf: plistUrl)
        let decoder = PropertyListDecoder()

        do {
            let config = try decoder.decode(HubspotConfig.self, from: plistData)
            logger.trace("Loaded config with portal id of \(config.portalId)")
            hublet = config.hublet
            portalId = config.portalId
            environment = config.environment
            defaultChatFlow = config.defaultChatFlow
            objectWillChange.send()

            sendPushTokenIfNeeded()

        } catch {
            logger.error("Error decoding plist - check all expected keys exist: \(error)")
            throw HubspotConfigError.missingConfiguration
        }
    }

    /// Configure SDK with given values
    /// - Parameters:
    ///   - portalId: Your portal id - you can find it from your hubspot account page
    ///   - hublet: Hublet name , typically "na1" or "eu1"
    ///   - defaultChatFlow: chat flow to use when none is specified when creating a chat. For example: sales
    ///   - environment: the environment to use
    func configure(portalId: String,
                   hublet: String,
                   defaultChatFlow: String?,
                   environment: HubspotEnvironment = .production)
    {
        self.portalId = portalId
        self.hublet = hublet
        self.environment = environment
        self.defaultChatFlow = defaultChatFlow

        objectWillChange.send()
    }

    /// Convenience to set the logger to the disabled logger
    public func disableLogging() {
        logger = Logger(.disabled)
    }

    /// Re-configures ``logger`` with the default logger config - if you want a specific logger category, configure ``logger`` directly instead
    public func enableLogging() {
        logger = createDefaultHubspotLogger()
    }

    /// Set the push token for the app. Recommend calling this each app launch when push feature is enabled.
    /// - Parameter apnsPushToken: The data token provided by iOS via didRegisterForRemoteNotificationsWithDeviceToken
    public func setPushToken(apnsPushToken: Data) {
        /// Only reset our state when it actually changes
        if pushToken != apnsPushToken {
            pushTokenSyncState = .notSent
        }

        pushToken = apnsPushToken
        sendPushTokenIfNeeded()
    }

    /// Sends the token if not already sent - only sends data when we have the token and its not being sent recently
    private func sendPushTokenIfNeeded() {
        guard let pushToken,
              let portalId
        else {
            // Not enough info, can't send yet
            return
        }

        sendPushTokenTask = Task {
            let shouldSendToken: Bool

            switch self.pushTokenSyncState {
            case .notSent:
                shouldSendToken = true

            case let .sending(lastActionDate):
                let interval = abs(lastActionDate.timeIntervalSinceNow)

                // If we have been 'sending' for more than a minute, clear and try again
                if interval > 60 {
                    shouldSendToken = true
                    self.pushTokenSyncState = .notSent
                } else {
                    shouldSendToken = false
                }

            case let .sent(lastActionDate):
                // Ignore new attempt to send if its within a brief window
                let interval = abs(lastActionDate.timeIntervalSinceNow)

                // Arbitary 20 second time to prevent double triggers in the case of repeated registration, setting identity at the same time, etc
                shouldSendToken = interval > 20
            }

            guard shouldSendToken else {
                return
            }

            let previousState = self.pushTokenSyncState
            self.pushTokenSyncState = .sending(.now)

            do {
                guard let hubletModel else {
                    throw HubspotConfigError.missingConfiguration
                }
                try await api.sendDeviceToken(hublet: hubletModel, token: pushToken, portalId: portalId)

                if !Task.isCancelled {
                    self.pushTokenSyncState = .sent(.now)
                } else {
                    self.pushTokenSyncState = previousState
                }
            } catch {
                logger.error("Error registering push token with API: \(error)")
                if case .sending = previousState {
                    // We shouldn't have had a previous state of sending ...
                    self.pushTokenSyncState = .notSent
                } else {
                    // Leave the value of sync state as it was, either with an older date or not sent yet
                    self.pushTokenSyncState = previousState
                }
            }
        }
    }

    /// Set the user id obtained from the [Visitor Identification API](https://developers.hubspot.com/docs/api/conversation/visitor-identification) , along with the users email address. These will be included when starting a chat session to identify the user. Its important to set these before starting a chat session, as they are needed during chat initialisation.
    ///
    /// Object will change is triggered after setting values, for anything that may be observing this manager with Combine or SwiftUI state
    ///
    /// Note: These values are only stored in memory and aren't persisted. Set them on each app launch or when changing user autentication status. This token has a short expiry, and should be re-set periodically.
    ///
    /// - Parameters:
    ///   - token: The token from the identity api. Must not be empty.
    ///   - email: The users email address, that matches the token. Must not be empty
    public func setUserIdentity(identityToken: String, email: String) {
        guard !identityToken.isEmpty, !email.isEmpty else {
            return
        }
        userIdentityToken = identityToken
        userEmailAddress = email
        objectWillChange.send()

        sendPushTokenIfNeeded()
    }

    /// Set a string key and value collection to be associate with any chat opened.
    ///
    /// Set optional and custom chat properies to send to hubspot on opening chat. These can be set at any time prior to starting a chat session.
    /// The data included here is sent to the Hubspot API only when opening a chat - if no chat is started the data is not sent anywere.
    ///
    /// You can use any key value, including custom keys, whatever makes sense your your application and use of chat for support or troubleshooting.
    ///
    /// For common, optional keys and values to use, for example to specify user location or permissions , see ``ChatPropertyKey``
    ///
    /// Avoid including personal, private information in property values, and only include data that you have permission from the user to use.
    ///
    /// The data passed here is combined with some automatic properties determined at run time - see the descriptions of the keys in ``ChatPropertyKey`` for information on automatically set values
    ///
    /// An example of setting a mix of pre-defined properties, and custom properties
    /// ```
    /// var properties: [String: String] = [
    ///     ChatPropertyKey.cameraPermissions.rawValue: self.checkCameraPermissions(),
    ///     "myapp-install-id": appUniqueId,
    ///     "subscription-tier": "premium"
    /// ]
    /// HubspotManager.shared.setChatProperties(data: properties)
    /// ```
    ///
    /// > Info: These properties are only retained in memory, and not persisted. Set preferred values at least once per app launch. They can be also replaced at any time by calling ``setChatProperties(data:)`` again.
    ///
    /// - seeAlso: ``ChatPropertyKey``
    public func setChatProperties(data: [String: String]) {
        chatProperties = data
    }

    /// Gathers together any user provided properties, as well as automatic properties into one collection. This will be the data included in API call
    func finalizeChatProperties() async -> [String: String] {
        // Start with developer provided ones, if any
        var properties = chatProperties

        let deviceModel = deviceModel()

        if !deviceModel.isEmpty {
            properties[ChatPropertyKey.deviceModel.rawValue] = deviceModel
        }

        if let pushToken {
            let encodedPushToken = pushToken.toHexString()
            properties[ChatPropertyKey.pushToken.rawValue] = encodedPushToken
        }

        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()

        if notificationSettings.alertSetting == .enabled || notificationSettings.notificationCenterSetting == .enabled {
            properties[ChatPropertyKey.notificationPermissions.rawValue] = "true"
        } else {
            properties[ChatPropertyKey.notificationPermissions.rawValue] = "false"
        }

        properties[ChatPropertyKey.operatingSystemVersion.rawValue] = "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"

        if let infoDict = Bundle.main.infoDictionary,
           let shortVersion = infoDict["CFBundleShortVersionString"],
           let buildVersion = infoDict["CFBundleVersion"]
        {
            properties[ChatPropertyKey.appVersion.rawValue] = "\(shortVersion).\(buildVersion)"
        }

        let screenBounds = UIScreen.main.bounds
        let screenWidth = screenBounds.width
        let screenHeight = screenBounds.height
        let scale = UIScreen.main.scale

        properties[ChatPropertyKey.screenSize.rawValue] = "\(Int(screenWidth))x\(Int(screenHeight))"
        properties[ChatPropertyKey.screenResolution.rawValue] = "\(Int(screenWidth * scale))x\(Int(screenHeight * scale))"
        properties[ChatPropertyKey.deviceOrientation.rawValue] = UIDevice.current.orientation.hubspotApiValue

        // ignore when battery is reported as -1, or some negative to indicate its invalid
        if UIDevice.current.batteryLevel >= 0 {
            let batteryLevelRounded = Int((UIDevice.current.batteryLevel * 100).rounded())
            properties[ChatPropertyKey.batteryLevel.rawValue] = String(batteryLevelRounded)
        }
        properties[ChatPropertyKey.batteryState.rawValue] = UIDevice.current.batteryState.hubspotApiValue

        // Platform is just fixed, no point in trying to detect it at runtime
        properties[ChatPropertyKey.platform.rawValue] = "ios"

        return properties
    }

    /// Delete all user specific data like identity tokens , email address,  custom chat properties etc from any in memory or local stores.
    /// Note: does not remove any property or user data from Hubspot remotely, except for attempting to remove the push token from the current user.
    public func clearUserData() {
        sendPushTokenTask?.cancel()

        /// First, remove the push token, if we can
        if let pushToken, let portalId, let hubletModel {
            Task {
                do {
                    try await api.deleteDeviceToken(hublet: hubletModel, token: pushToken, portalId: portalId)
                } catch {
                    logger.error("Error deleting push token from api: \(error)")
                }

                // either way, clear our stored token
                self.pushToken = nil
                self.pushTokenSyncState = .notSent
            }
        }

        userIdentityToken = nil
        userEmailAddress = nil
        chatProperties = [:]
        objectWillChange.send()
    }

    /// Computes the url for the current config for embedding chat, based on any known config for portal id, hublet, user id, etc
    ///
    /// The chat view , ``HubspotChatView`` calls this method when setting up its embedded chat
    /// - Parameters:
    ///     - withPushData: The struct with data from push notification
    ///     - forChatFlow: The chat flow to open.
    /// - Returns: URL to embed to show mobile chat
    ///  - Throws: ``HubspotConfigError.missingConfiguration`` if app settings like portal id or hublet are missing, or ``HubspotConfigError.missingChatFlow`` if no chat flow is provided and no default value exists
    func chatUrl(withPushData: PushNotificationChatData?, forChatFlow: String? = nil) throws -> URL {
        guard let hublet,
              let portalId
        else {
            throw HubspotConfigError.missingConfiguration
        }

        let hubletModel = Hublet(id: hublet, environment: environment)

        var components = URLComponents()
        components.scheme = "https"
        components.host = hubletModel.hostname
        components.path = "/conversations-visitor-embed"

        var queryItems: [String: String] = [
            "portalId": portalId,
            "hublet": hubletModel.id,
            "env": environment.rawValue,
        ]

        if let idToken = userIdentityToken {
            queryItems["identificationToken"] = idToken
        }

        if let email = userEmailAddress {
            queryItems["email"] = email
        }

        // Use chat flow from push data, if exsist, otherwise use chat flow dedicated property
        if let chatFlow = withPushData?.chatflow, !chatFlow.isEmpty {
            queryItems["chatflow"] = chatFlow
        } else if let chatFlow = forChatFlow, !chatFlow.isEmpty {
            queryItems["chatflow"] = chatFlow
        } else if let defaultChatFlow, !defaultChatFlow.isEmpty {
            queryItems["chatflow"] = defaultChatFlow
        } else {
            // No chatflow, but we know we need one
            throw HubspotConfigError.missingChatFlow
        }

        var urlNoPlus = CharacterSet.urlQueryAllowed
        urlNoPlus.remove("+")

        // Manually encode query string, as + is a common component in emails and we don't want + appearing un-encoded as it would be if we used the query item collection on components
        // Note: if we ever need values with spaces, we might need to update this handling to handle values when email is/isn't the key differently
        components.percentEncodedQuery = queryItems.compactMap {
            guard
                let key = $0.addingPercentEncoding(withAllowedCharacters: urlNoPlus),
                let value = $1.addingPercentEncoding(withAllowedCharacters: urlNoPlus)
            else {
                return nil
            }

            return key + "=" + value
        }
        .joined(separator: "&")

        guard let url = components.url else {
            throw HubspotConfigError.missingConfiguration
        }

        return url
    }

    /// Handle obtaining a thread id - once the thread id is known , we can post chat properties to the API. This method is used by chat views once they've extracted ID from UI / Javascript Bridge.
    /// - Parameter threadId: the thread id retrieved from the active chat view
    func handleThreadOpened(threadId: String) {
        guard let portalId, let hubletModel else {
            return
        }

        // Call the api. Creating a task here instead of making this method async because right now we don't need to do anything after
        Task {
            // Get the properties we want to send to the api
            let props = await finalizeChatProperties()

            do {
                try await api.sendChatProperties(hublet: hubletModel,
                                                 properties: props,
                                                 visitorIdToken: self.userIdentityToken,
                                                 email: self.userEmailAddress,
                                                 threadId: threadId,
                                                 portalId: portalId)
            } catch {
                logger.error("Error sending chat properties: \(error)")
            }
        }
    }
}

// These are test functions just used during early development - kept in an extension to make them more obvious for deletion later
public extension HubspotManager {
    /// Ignore - used for early testing in the demo application, and will be removed in the future.
    func debug_emitSomeLogs() {
        logger.trace("This is a trace log")
        logger.info("This is an info log , the app bundle id is \(Bundle.main.bundleIdentifier ?? "Unknown")")
    }
}

public extension Image {
    /// Exporting chat icon - initially for demo use - but maybe sharing some resources that aren't buttons or views might be needed eventually, if so refactor this
    static var hubspotChatImage: Image {
        Image(.genericChatIcon)
    }
}

public extension HubspotManager {
    /// Create a visitor access token directly using app access token
    ///
    /// Convenience for creating a visitor identity token using the given details, for situations where server infrastructure isn't available during SDK development.
    ///
    ///  > Warning: Embedding access token for your product in app is not recommended - This was originally for demo purposes, and may be removed. Strongly consider creating a token as part of app server infrastructure instead.
    ///
    /// - Parameters:
    ///   - accessToken: The access token for your application, as returned by the Hubspot dashboard
    ///   - email: the email of the user
    ///   - firstName: users first name
    ///   - lastName: users last name
    /// - Returns: The generated JWT token
    @available(*, deprecated, message: "This is for development only and may be removed - acquiring an access token should be done as part of your products server infrastructure")
    func aquireUserIdentityToken(accessToken: String, email: String, firstName: String, lastName: String) async throws -> String {
        guard let hubletModel else {
            throw HubspotConfigError.missingConfiguration
        }

        return try await api.createVisitorToken(hublet: hubletModel, accessToken: accessToken, email: email, firstName: firstName, lastName: lastName)
    }
}
