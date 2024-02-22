// PushNotificationChatData.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import UserNotifications

/// Holds all the data that is hubspot specific, extracted from a push notification collection. A convenient way to bundle all the known parameters together for passing along from notification delegate to the chat view
///
/// Push messages contain additional keys like so:
///
/// ```json
/// "hsPortalId": "abc123",
/// "hsChatflowId": "id",
/// "hsThreadId": "threadId",
/// "hsChatflowParam": "sales"
/// ```
/// These keys are also defined as constants here, ``chatflowKey`` , ``chatflowIdKey``, ``threadIdKey`` , ``portalIdKey``
///
/// The presence of any of these keys is use to indicate that the push message is for a hubspot chat. They are used by the helper method ``HubspotManager/isHubspotNotification(notification:)`` or ``HubspotManager/isHubspotNotification(notificationData:)``
///
public struct PushNotificationChatData {
    /*
        "hsPortalId": "abc123",
        "hsChatflowId": "id",
        "hsThreadId": "threadId",
        "hsChatflowParam": "sales"
     */

    /// Push messages contain the portal id in the payload, with the key `hsPortalId`
    public static let portalIdKey = "hsPortalId"

    /// Push messages contain the chat flow id in the payload, with the key `hsChatflowId`
    public static let chatflowIdKey = "hsChatflowId"

    /// Push messages contain the thread id in the payload, with the key `hsThreadId'`
    public static let threadIdKey = "hsThreadId"

    /// Push messages contain the chat flow name in the payload, with the key `hsChatflowParam`
    public static let chatflowKey = "hsChatflowParam"

    /// The portal id, if present. Can be used for validation.
    public let portalId: String?
    /// The chatflow id , if present. unused currently.
    public let chatflowId: String?
    /// The thread id, if present - not currently used in the embedded chat.
    public let threadId: String?
    /// The chatflow to open when handling the notification
    public let chatflow: String?

    /// Create instance using the notification if any key is present, or returns nil when no keys are present
    public init?(notification: UNNotification) {
        self.init(notificationData: notification.request.content.userInfo)
    }

    /// Create instance using the user info dictionary if any key is present, or returns nil when no keys are present
    public init?(notificationData: [AnyHashable: Any]) {
        portalId = notificationData[Self.portalIdKey] as? String
        chatflow = notificationData[Self.chatflowKey] as? String
        chatflowId = notificationData[Self.chatflowIdKey] as? String
        threadId = notificationData[Self.threadIdKey] as? String

        // We want at least one key to be set, otherwise return nil
        if portalId == nil, chatflow == nil, chatflowId == nil, threadId == nil {
            return nil
        }
    }
}
