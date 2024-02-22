// HubspotUserProperties.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import UIKit

/// These are the known , pre-defined key values for chat properties.
///
/// These values may be expected by Hubspot to be set in some situations, or to enable optional functionality if present.
///
/// If including chat properties in your application, if possible use these keys where appropiate rather than custom key names. Use the raw value as key values when setting chat properties on ``HubspotManager`` using  ``HubspotManager/setChatProperties(data:)`` function. Use the `rawValue` property like so:
///
/// ```
///  manager.setChatProperties(data:[
///         ChatPropertyKey.location.rawValue: "....."
///  ])
/// ```
///
/// Avoid including personal, private information in property values, and only include data that you have permission from the user to use.
public enum ChatPropertyKey: String {
    /// Optional. Use this key with the value 'true' or 'false' to record if your app has camera permissions granted.
    ///
    /// `api key: camera_permissions`
    case cameraPermissions = "camera_permissions"
    /// Optional. Use this key with the value 'true' or 'false' to record if your app has photo permissions granted.
    ///
    /// `api key: photo_library_permissions`
    case photoPermissions = "photo_library_permissions"
    /// Automatic. This key and value is set automatically. Its set to true when there's permission granted to show notifications as alerts or in the notification centre, either as full permission or provisional permission
    ///
    /// `api key: notification_permissions`
    case notificationPermissions = "notification_permissions"
    /// Optional. Use this key with the value 'true' or 'false' to record if your app has location permissions granted.
    ///
    /// `api key: location_permissions`
    case locationPermissions = "location_permissions"
    /// Optional. Use this key with a location for the user, formatted as latitude,longitude , for example , "51.51148,-0.12266". This may be useful information for your support requests.
    ///
    /// `api key: location`
    case location
    /// Automatic: This key value is set automatically when using push notification features of the sdk.
    ///
    /// `api key: push_token`
    case pushToken = "push_token"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations.
    /// Note - iOS reports model numbers differently with the device code, than how they are marketed. Instead of iPhone 15 Pro , one would get "iPhone16,1"
    ///
    /// `api key: device_model`
    case deviceModel = "device_model"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. The value format is the platform, for example "ios"
    ///
    /// `api key: platform`
    case platform
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. The value format is the platform followed by version , for example "iOS 17.2"
    ///
    /// `api key: os_version`
    case operatingSystemVersion = "os_version"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations - the value is read from the main budle version keys, formatted as (CFBundleShortVersionString).(CFBundleVersion)
    ///
    /// `api key: app_version`
    case appVersion = "app_version"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. Value is set to unknown, portrait, or landscape
    ///
    /// `api key: device_orientation`
    case deviceOrientation = "device_orientation"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. Value is formated as widthxheight
    ///
    /// `api key: screen_size`
    case screenSize = "screen_size"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. Value is formated as widthxheight
    ///
    /// `api key: screen_resolution`
    case screenResolution = "screen_resolution"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. The battery level is a percentage from 0 to 100.
    ///
    /// `api key: battery_level`
    case batteryLevel = "battery_level"
    /// Automatic: This key and value is set automatically by the sdk when opening chat conversations. The value is the same as the `UIDevice.BatteryState` enum names, and can be:
    /// unknown, full, charging, unplugged
    ///
    /// `api key: battery_state`
    case batteryState = "battery_state"
}

extension UIDeviceOrientation {
    var hubspotApiValue: String {
        switch self {
        case .portrait, .portraitUpsideDown:
            return "portrait"
        case .landscapeLeft, .landscapeRight:
            return "landscape"
        default:
            return "unknown"
        }
    }
}

extension UIDevice.BatteryState {
    var hubspotApiValue: String {
        switch self {
        case .unknown:
            return "unknown"
        case .charging:
            return "charging"
        case .full:
            return "full"
        case .unplugged:
            return "unplugged"
        @unknown default:
            return "unknown"
        }
    }
}
