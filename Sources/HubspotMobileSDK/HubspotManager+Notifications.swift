// HubspotManager+Notifications.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import NotificationCenter

extension HubspotManager {
    /// Alternative to ``newMessage`` publisher or ``newMessageCallback`` property , potentially useful in a SwiftUI view
    ///
    /// This could be used in a stand alone task like so:
    ///
    /// ```swift
    /// Task {
    ///    for await notification in HubspotManager.shared.newMessages() {
    ///       self.triggerChatFlow()
    ///    }
    ///
    /// }
    /// ```
    /// or attached to a view:
    /// ```swift
    /// myView
    ///   .frame(...)
    ///   .background(...)
    ///   .task {
    ///     for await _ in HubspotManager.shared.newMessages() {
    ///        presentChatView = true
    ///     }
    /// }
    /// ```
    /// > Warning: This async stream normally will never terminate.
    ///
    public func newMessages() -> AsyncStream<PushNotificationChatData> {
        return AsyncStream { cont in

            // Supressing sendability issue with cancellable - should be ok to send to the onTermination, as nothing else will have a reference to it
            nonisolated(unsafe) let pubCancellable = self.newMessage.sink(
                receiveCompletion: { _ in
                    // doesn't matter if the subscription fails or finishes, our sequence is done - in this specific case we expect it never to do either , but just incase, end the stream.
                    cont.finish()
                },
                receiveValue: { data in
                    cont.yield(data)
                })

            cont.onTermination = { termination in
                switch termination {
                case .cancelled:
                    // If the termination was from the task / stream side , the subscription itself is still active, so attempt to cancel it
                    pubCancellable.cancel()
                case .finished:
                    // Do nothing if we finished the stream - that only happens when the subscription itself finished
                    break
                @unknown default:
                    pubCancellable.cancel()
                }
            }
        }
    }

    /// This is a convenience method for allowing this HubspotManager instance to act as your UNUserNotificationCenterDelegate. This will check any notifications received for hubspot messages.
    ///
    ///  If using the HubspotManager to handle notifications, call this before the end of app launch to ensure all notifications are handled.
    ///
    /// If you would prefer to present notification permission dialog at a specific time, or as part of a primer screen, set promptForNotificationPermissions to false. If you have no preference for when to prompt the user , set promptForNotificationPermissions to true, and the user will be prompted if permissions are not yet granted.
    ///
    /// It's also ok to call this multiple times - you might call `configurePushMessaging(promptForNotificationPermissions: false, allowProvisionalNotifications: true, newMessageCallback: myHandler)` during your app start up or initial setup, and later after user enables a setting or accesses a particular feature, call `configurePushMessaging(promptForNotificationPermissions: true, allowProvisionalNotifications: true, newMessageCallback: myHandler)` to trigger the prompt for permissions.
    ///
    /// **Warning** This will set the delegate for the current UNUserNotificationCenter - if you need to handle UNUserNotificationCenterDelegate callbacks in your app, do not use this method.
    ///
    /// If the app should show chat UI in response to the user tapping a notification, newMessageCallback is triggered. Use this closure to configure your UI.
    /// - Parameters:
    ///   - promptForNotificationPermissions: If true, and notification permissions are not yet granted, the user is prompted to allow notifications
    ///   - allowProvisionalNotifications: If `promptForNotificationPermissions` is false, set this to true to enable provisional notifications if not already granted. Has no effect if `promptForNotificationPermissions` is true.
    ///   - newMessageCallback: Use this closure to configure your UI to show chat view. Called on the main thread. If nil, the call back isn't changed from any previous configuration. Alternatively, leave as nil , and set ``HubspotManager/newMessageCallback`` property directly.  or use the ``HubspotManager/newMessage`` publisher property
    public func configurePushMessaging(
        promptForNotificationPermissions: Bool,
        allowProvisionalNotifications: Bool,
        newMessageCallback: ((PushNotificationChatData) -> Void)? = nil
    ) {
        UIApplication.shared.registerForRemoteNotifications()

        // Act as the delegate for opening notifications so we can tell when someone opens one.
        UNUserNotificationCenter.current().delegate = self

        if promptForNotificationPermissions {
            Task.detached {
                let currentSettings = await UNUserNotificationCenter.current().notificationSettings()
                // We only want to request auth if not yet asked or just provisional
                if currentSettings.authorizationStatus == .notDetermined || currentSettings.authorizationStatus == .provisional {
                    do {
                        let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                        if authorized {
                            await self.logger.trace("Notification permission granted")
                        }
                    } catch {
                        await self.logger.error("Unable to request notification permissions: \(error)")
                    }
                }
            }
        } else if allowProvisionalNotifications {
            Task.detached {
                let currentSettings = await UNUserNotificationCenter.current().notificationSettings()
                // We only want to request auth if not yet asked
                if currentSettings.authorizationStatus == .notDetermined {
                    do {
                        let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.provisional])
                        if authorized {
                            await self.logger.trace("Provisional notification settings enabled")
                        }
                    } catch {
                        await self.logger.error("Unable to request notification permissions: \(error)")
                    }
                }
            }
        }

        if let newMessageCallback {
            self.newMessageCallback = newMessageCallback
        }
    }
}

/// Making the `HubspotManager` your user notification delete is not required, but its an option for convenience in situations where another delegate doesn't already exist.
extension HubspotManager: UNUserNotificationCenterDelegate {
    /// Use this method to help identify incoming notifications that are hubspot related , incase you wish to handle them differently
    public nonisolated func isHubspotNotification(notification: UNNotification) -> Bool {
        let notificationData = notification.request.content.userInfo
        return isHubspotNotification(notificationData: notificationData)
    }

    /// Use this method to help identify incoming notifications that are hubspot related , incase you wish to handle them differently
    public nonisolated func isHubspotNotification(notificationData: [AnyHashable: Any]) -> Bool {
        let hasAHubspotKey = notificationData.contains(where: { key, _ in
            guard let key = key as? String else {
                return false
            }

            // There's a few of keys we can potentially have here
            return
                key.hasPrefix(PushNotificationChatData.chatflowIdKey) || key.hasPrefix(PushNotificationChatData.chatflowKey) || key.hasPrefix(PushNotificationChatData.portalIdKey) || key.hasPrefix(PushNotificationChatData.threadIdKey)
        })

        return hasAHubspotKey
    }

    /// A ``HubspotManager`` instanance, like ``HubspotManager/shared`` can be used as a notification centre delegate, in situations where all notifications are from hubspot. If you have your own notification delegate, instead call this method from within your own delegate for notifications that are hubspot related.
    ///
    ///
    public nonisolated func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if isHubspotNotification(notification: response.notification) {
            guard let chatData = PushNotificationChatData(notification: response.notification) else {
                // none of the expected data in the message
                return
            }

            // dispatching on main as most likely will result in ui changes - incase not everyone remembers to enforce processing on main thread for presentations
            DispatchQueue.main.async {
                self.newMessageCallback(chatData)
                self.newMessage.send(chatData)
            }
        } else {
            let requestId = response.notification.request.identifier
            Task {
                await self.logger.info("Push message handled by HubspotManager that isn't detected as as Hubspot notifiation. This may be a misconfiguration. Response id: \(requestId)")
            }
        }
        completionHandler()
    }

    /// A ``HubspotManager`` instanance, like ``HubspotManager/shared`` can be used as a notification centre delegate, in situations where all notifications are from hubspot. If you have your own notification delegate, instead call this method from within your own delegate for notifications that are hubspot related.
    ///
    public nonisolated func userNotificationCenter(_: UNUserNotificationCenter, willPresent _: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
