// HubspotManager+Properties.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import UIKit  // Needed for UIDevice

extension HubspotManager {
    /// Called by ui components if a chat might potentially happen - allows manager class to enable anything that needs prep time - like battery monitoring ahead of gathering it.
    /// Internal for now - if its not enough to be called in the chat view, it can be made public and a requirement to be called from custom components.
    func prepareForPotentialChat() {
        enableBatteryMonitoring()
        enableOrientationMonitoring()
    }

    func enableOrientationMonitoring() {
        if !UIDevice.current.isGeneratingDeviceOrientationNotifications {
            didWeEnableOrientationMonitoring = true
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        }
    }

    func enableBatteryMonitoring() {
        if !UIDevice.current.isBatteryMonitoringEnabled {
            didWeEnableBatterMonitoring = true
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
    }

    /// Fetch the system model , converting c struct into normal string. Uses utsname function and reflection.
    /// The result is the apple model number, like iPhone15,4 , iPhone16,1 , etc rather than marketing name like "Pro Max"
    func deviceModel() -> String {
        var info = utsname()  // create empty struct
        uname(&info)  // populate it

        /// We can't iterate over a tuple of characters, nor can we use the init methods that take an array of cchars, so reflection to loop over them instead
        let mirror = Mirror(reflecting: info.machine)
        let parts: [String] = mirror.children.compactMap { charProperty -> String? in
            // 0 would be end of string
            guard let intChar = charProperty.value as? Int8, intChar > 0 else {
                return nil
            }

            guard let scalar = UnicodeScalar(UInt32(intChar)) else {
                return nil
            }
            return String(scalar)
        }

        return parts.joined()
    }
}
