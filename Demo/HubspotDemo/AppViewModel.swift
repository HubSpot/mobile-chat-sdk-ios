// AppViewModel.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import AVFoundation
import Combine
import Foundation
import HubspotMobileSDK
import UIKit

class AppViewModel: ObservableObject {
    @Published var hubspotSdkFailure = false
    @Published var hubspotError: LocalizedError? = nil

    @Published var customProperties: [CustomProperty] = [CustomProperty(key: "example-key", value: "example value")]

    /// set false to block registering for testing
    private let canRequestPush = true

    let notificationDelegate: DemoAppNotificationDelegate
    private(set) weak var appDelegate: DemoAppDelegate? = nil

    private var subs: Set<AnyCancellable> = []

    /// We need to link some components together to gather various notification outputs in one place
    func configure(_ appDelegate: DemoAppDelegate) {
        self.appDelegate = appDelegate
    }

    func setupHubspot() {
        do {
            try HubspotManager.configure()

            // If we already configured the demo with a token and email previously, re-set the user identity
            if let existingToken: String = UserDefaults.standard[.idToken],
               let existingEmail: String = UserDefaults.standard[.userEmail]
            {
                HubspotManager.shared.setUserIdentity(identityToken: existingToken, email: existingEmail)
            }

            setChatProperties()

        } catch {
            hubspotError = error as? LocalizedError
            hubspotSdkFailure = true
            logger.error("Error configuring Hubspot SDK: \(error)")
        }
    }

    init() {
        notificationDelegate = DemoAppNotificationDelegate()

        // Configure Hubspot Manager before we set the notification delegate, otherwise, if a notification is being opened, there's no known portal id set

        setupHubspot()
        UNUserNotificationCenter.current().delegate = notificationDelegate

        setChatProperties()

        // somewhat clunky chaining of reloads as we aren't using new Observable framework
        notificationDelegate.objectWillChange.sink {
            self.objectWillChange.send()
        }
        .store(in: &subs)
    }

    func addCustomProperty(key: String, value: String) {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)

        let property = CustomProperty(key: key, value: value)
        if let idx = customProperties.firstIndex(where: { $0.key == key }) {
            customProperties[idx] = property
        } else {
            customProperties.append(property)
        }

        // Set updated list on Hubspot manager
        setChatProperties()
    }

    /// Set some example properties on the Hubspot sdk
    func setChatProperties() {
        let cameraAllowed = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

        // A real app may also want to assoicate a specific id that only makes sense to itself - here lets just use vendor id as an example
        let appUniqueId = UIDevice.current.identifierForVendor?.uuidString ?? "demo-app"

        var myProperties: [String: String] = customProperties.reduce([:]) { dictionary, prop in
            var dictionary = dictionary
            dictionary[prop.key] = prop.value
            return dictionary
        }

        // Here we have an example of using a pre-defined key as well as a custom one
        myProperties[ChatPropertyKey.cameraPermissions.rawValue] = String(cameraAllowed)
        myProperties["myapp-install-id"] = appUniqueId

        HubspotManager.shared.setChatProperties(data: myProperties)
    }

    func registerForPush() {
        guard canRequestPush else {
            return
        }

        UIApplication.shared.registerForRemoteNotifications()
    }
}

/// Constants used to access user defaults storage in multiple places
enum StorageKeys: String {
    case idToken
    case userEmail
}

extension UserDefaults {
    subscript<T>(storageKey: StorageKeys) -> T? {
        get {
            object(forKey: storageKey.rawValue) as? T
        }
        set {
            setValue(newValue, forKey: storageKey.rawValue)
        }
    }
}

struct CustomProperty: Identifiable, Codable {
    let key: String
    let value: String

    var id: String {
        key
    }
}
