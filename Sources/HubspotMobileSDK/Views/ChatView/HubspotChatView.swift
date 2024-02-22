// HubspotChatView.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI
import WebKit

/// A SwiftUI view containing Hubspots chat interface. This chat view is intended to be presented modally, with a sheet, for easy dismissal, or as a full screen cover.
/// > Warning: The chat view also includes an option to take a photo - be sure to include NSCameraUsageDescription in your apps info plist to enable camera functionality. Not doing so may result in a crash if your user attempts to attach a photo.
///
/// As an example for how to present a chat view from a user button:
/// ```swift
/// Button(action: {
///     showChat.toggle()
/// }, label: {
///     Text("\(Image(systemName: "message.badge.circle.fill")) Chat Now (sheet/modal)")
///
///
/// }).sheet(isPresented: $showChat, content: {
///     HubspotChatView(manager: HubspotManager.shared)
/// })
/// ```
///
/// If you want to show a specific chat flow, that flow can be specificed by setting the optional chat flow parameter when creating the view:
///
/// ```swift
/// HubspotChatView(manager: HubspotManager.shared, chatFlow: "support")
/// ```
///
/// ### Opening Chat From Push Notification
///
/// If opening chat view in response to a push notification , ideally extract important information from the notification using the ``PushNotificationChatData`` struct , and pass to the initialiser like so:
/// ```swift
/// HubspotChatView(manager: HubspotManager.shared, pushData: selectedChatData)
/// ```
///
/// > Important: HubspotChatView doesn't insert any close buttons when overlaid with sheet or full screen cover. Consider adding a close toolbar button if that is needed.
///
///
///
public struct HubspotChatView: UIViewRepresentable {
    public typealias UIViewType = WKWebView

    private let manager: HubspotManager
    private let chatFlow: String?
    private let pushData: PushNotificationChatData?

    /// Create the chat view, optionally specifying the HubspotManager and Chat Flow to use.
    ///
    /// > Info: chatFlow may only take effect if a valid user identity is configured. See ``HubspotManager/setUserIdentity(identityToken:email:)``
    ///
    /// - Parameters:
    ///   - manager: manager to use when creating urls for account and getting user properties
    ///   - pushData: Struct containing any of the hubspot values from the push body payload.
    ///   - chatFlow: The specific chat flow to open, if any
    public init(manager: HubspotManager = HubspotManager.shared,
                pushData: PushNotificationChatData? = nil,
                chatFlow: String? = nil)
    {
        self.manager = manager
        self.chatFlow = chatFlow
        self.pushData = pushData
    }

    public func makeCoordinator() -> WebviewCoordinator {
        return WebviewCoordinator(manager: manager)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        configuration.applicationNameForUserAgent = "HubspotMobileSDK"
        configuration.websiteDataStore = .default()

        configuration.dataDetectorTypes = [.phoneNumber]

        if #available(iOS 15.4, *) {
            configuration.preferences.isElementFullscreenEnabled = true
        }

        configuration.preferences.isTextInteractionEnabled = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        configuration.userContentController = context.coordinator.contentController
        context.coordinator.setupScripts()

        let webview = WKWebView(frame: .zero, configuration: configuration)

        webview.isOpaque = false
        webview.backgroundColor = UIColor.systemBackground
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator

        // Its likely safe to trigger this from here - if we are preparing our ui for chat, likelihood is we will soon have an id and need to report properties.
        manager.prepareForPotentialChat()

        return webview
    }

    /// This will load the chat url in the website, if available. Called automatically.
    public func updateUIView(_ webView: WKWebView, context: Context) {
        do {
            let urlToLoad = try manager.chatUrl(withPushData: pushData, forChatFlow: chatFlow)
            let request = URLRequest(url: urlToLoad)

            let mainLoadNavReference = webView.load(request)
            context.coordinator.mainLoadNavReference = mainLoadNavReference
        } catch {
            manager.logger.error("Unable to load chat. Webview will be blank. \(error)")
        }
    }

    /// The coordinator helps with the Swift View to UIView lifecycle , and stays alive (along with the UIKit views)  when the swift view itself may be recreated.
    /// This is the sensible place for our delegate callbacks
    public class WebviewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let manager: HubspotManager

        init(manager: HubspotManager) {
            self.manager = manager
        }

        let handlerName = "nativeApp"
        let contentController = WKUserContentController()

        var mainLoadNavReference: WKNavigation?

        func setupScripts() {
            contentController.add(self, name: handlerName)

            let js = """
                window.webkit.messageHandlers.nativeApp.postMessage({"info":"setupScripts"});
            """

            contentController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

            // create script that triggers on hubspot event, and calls our message handler

            let configCallbacksJS = """
            function configureHubspotConversations() {
                if (window.HubSpotConversations) {
                    window.webkit.messageHandlers.nativeApp.postMessage({ "info": "Setting up handlers" });
                    window.HubSpotConversations.on('conversationStarted', payload => {
                        window.webkit.messageHandlers.nativeApp.postMessage(payload);
                    });

                    window.HubSpotConversations.on('widgetLoaded', payload => {
                        window.webkit.messageHandlers.nativeApp.postMessage(payload);
                    });

                    window.HubSpotConversations.on('userInteractedWithWidget', payload => {
                        window.webkit.messageHandlers.nativeApp.postMessage(payload);
                    });

                    window.HubSpotConversations.on('userSelectedThread', payload => {
                        window.webkit.messageHandlers.nativeApp.postMessage(payload);
                    });

                    window.webkit.messageHandlers.nativeApp.postMessage({ "info": "Finished setting up handlers" });
                } else {
                    window.webkit.messageHandlers.nativeApp.postMessage({ "info": "no object to set handlers on still" });
                }
            }

            window.webkit.messageHandlers.nativeApp.postMessage({ "info": "starting main load script" });

            if (window.HubSpotConversations) {
                configureHubspotConversations();
            } else {
                window.hsConversationsOnReady = [configureHubspotConversations];
            }

            window.webkit.messageHandlers.nativeApp.postMessage({ "info": "finished main load script" });
            """

            contentController.addUserScript(WKUserScript(source: configCallbacksJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        }

        public func webView(_: WKWebView, didCommit navigation: WKNavigation!) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                // create script that triggers on hubspot event, and calls our message handler
                // Set earlier currently, but might need to move back there
            }
        }

        public func webView(_: WKWebView, didFinish navigation: WKNavigation!) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                // create script that triggers on hubspot event, and calls our message handler
                // Set earlier currently, but might need to move back there
            }
        }

        public func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any] {
                // We are looking to get conversation object , if sent.
                if
                    let conversationDict = dict["conversation"] as? [String: Any],
                    let conversationId = conversationDict["conversationId"] as? Int
                {
                    // Now we know the id of newly selected thread, we can inform the manager which will handle next steps for data
                    manager.handleThreadOpened(threadId: String(conversationId))
                }
            }
        }
    }
}
