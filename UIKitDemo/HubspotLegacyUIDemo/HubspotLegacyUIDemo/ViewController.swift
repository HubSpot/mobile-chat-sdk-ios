// ViewController.swift
// Hubspot Mobile SDK - UIKit Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import Combine
import HubspotMobileSDK
import SwiftUI
import UIKit

class ViewController: UIViewController {
    var notificationSub: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Use Combine to listen for new messages being opened, and present UI when that happens. Could alternatively use the `newMessageCallback` property
        notificationSub = HubspotManager.shared.newMessage.sink { [weak self] data in
            self?.showChat(data: data)
        }

        // We could also use Tasks, which are more useful for SwiftUI
        Task {
            for await newMessage in HubspotManager.shared.newMessages() {
                logger.trace("This is the infinite for await in the VC triggering on new message")
                // showChat()
            }
        }
    }

    @IBAction
    func onEnablePushPress(_: Any) {
        HubspotManager.shared.configurePushMessaging(
            promptForNotificationPermissions: true,
            allowProvisionalNotifications: true,
            newMessageCallback: nil)
    }

    @IBAction
    func onChatButtonPress(_: Any) {
        showChat(data: nil)
    }

    func showChat(data: PushNotificationChatData?) {
        let chatView = HubspotChatView(pushData: data)
        // Create a hosting controller to hold the chat view
        let hostingVC = UIHostingController(rootView: chatView)

        present(hostingVC, animated: true)
    }
}
