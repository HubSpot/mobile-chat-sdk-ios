// AppDelegate.swift
// Hubspot Mobile SDK - UIKit Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import Combine
import HubspotMobileSDK
import OSLog
import UIKit

/// Default log for demo app
let logger = Logger()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // This will configure the SDK using the `Hubspot-Info.plist` file that is bundled in app
        try! HubspotManager.configure()

        // We want sdk to handle our push notifications
        HubspotManager.shared.configurePushMessaging(promptForNotificationPermissions: false,
                                                     allowProvisionalNotifications: true,
                                                     newMessageCallback: { _ in
                                                         logger.trace("This is the callback indicating that a new message was opened")
                                                     })

        // There can only be one callback set for new push messages being opened, but
        // alternatively, tasks could be used in multiple places

        Task {
            for await _ in HubspotManager.shared.newMessages() {
                logger.trace("This is the app delegate never ending task handling another new message")
            }
            logger.trace("This is never reached")
        }

        return true
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Forward device token to hubspot SDK
        HubspotManager.shared.setPushToken(apnsPushToken: deviceToken)
        // Note, you may have other content here already for other
    }
}
