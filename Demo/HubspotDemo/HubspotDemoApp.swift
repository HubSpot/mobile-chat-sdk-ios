// HubspotDemoApp.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import OSLog
import SwiftUI

/// Default log for demo app
let logger = Logger()

@main
struct HubspotDemoApp: App {
    @UIApplicationDelegateAdaptor(DemoAppDelegate.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase

    @StateObject var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ChooseDemoView()
                .environmentObject(appViewModel)
                .task {
                    appViewModel.configure(appDelegate)
                }
                .onChange(of: scenePhase, perform: { val in
                    if val == .active {
                        appViewModel.registerForPush()
                        appViewModel.setChatProperties()
                    }
                })
        }
    }
}

/// Example of a app level notification delegate that also forwards calls to hubspot delegate
class DemoAppNotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    /// Count of recent pushes received in the foreground
    @Published var countOfpushesReceived = 0
    /// Count of the notifications received we think are for hubspot content
    @Published var countOfHubspotPushesReceived = 0

    /// Count of recent pushes tapped on
    @Published var countOfpushesOpened = 0
    /// Count of the notifications tapped on we think are related to hubspot
    @Published var countOfHubspotPushesOpened = 0

    /// This is set when a user selects a notification unrelated to the chat feature, perhaps its some other app feature we don't want to confuse with chat.
    @Published var selectedAppNotification: UNNotification? = nil

    /// This is set when a user selects a chat notification specificallty - subscribe to this to present ui after selection
    @Published var selectedChatNotification: PushNotificationChatData? = nil

    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "DemoAppNotificationDelegate")

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive notificationResponse: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        logger.trace("didReceive notifcation reponse: \(notificationResponse.actionIdentifier), for \(notificationResponse.notification.request.identifier)")

        /// This function is the only one called when we don't use background push , and the app is open
        countOfpushesOpened += 1
        if HubspotManager.shared.isHubspotNotification(notification: notificationResponse.notification) {
            countOfHubspotPushesOpened += 1
            selectedChatNotification = PushNotificationChatData(notification: notificationResponse.notification)

            /// As well as the custom handling above, we could optionally forward our messages to the manager, so it can trigger the newMessage callbacks / publishers, if that was a preferred hook for opening them
            HubspotManager.shared.userNotificationCenter(center, didReceive: notificationResponse, withCompletionHandler: {})

        } else {
            selectedAppNotification = notificationResponse.notification
        }
        completionHandler()
    }

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.trace("willPresent notification: \(notification.request.identifier)")

        /// This function is the only one called when we don't use background push , and the app is open
        countOfpushesReceived += 1
        if HubspotManager.shared.isHubspotNotification(notification: notification) {
            countOfHubspotPushesReceived += 1
        }

        completionHandler([.banner, .sound])
    }
}

class DemoAppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var deviceToken: Data? = nil

    // Timestamp for when we refreshed the token - even when its the same this is updated
    @Published var tokenDate: Date? = nil

    /// Count of recent pushes received
    @Published var countOfpushesReceived = 0
    /// Count of the notifications we think are for hubspot content
    @Published var countOfHubspotPushesReceived = 0

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        logger.debug("Demo app got access to the token: \(deviceToken.toHexString(), privacy: .private)")
        self.deviceToken = deviceToken
        tokenDate = .now
        HubspotManager.shared.setPushToken(apnsPushToken: deviceToken)
    }

    func application(_: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.debug("remote notification received (completion handler): \(userInfo)")

        countOfpushesReceived += 1
        if HubspotManager.shared.isHubspotNotification(notificationData: userInfo) {
            countOfHubspotPushesReceived += 1
        }

        completionHandler(.noData)
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError _: Error) {
        logger.error("Error registering for push: Check that the demo app is configured corrrectly with push config / entitlements")
    }
}

extension Data {
    /// Used to encode push tokens
    /// - Returns: The data in hex format, lowercase
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
