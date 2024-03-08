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
///
public struct HubspotChatView: View {
    private let manager: HubspotManager
    private let chatFlow: String?
    private let pushData: PushNotificationChatData?

    @StateObject var viewModel = ChatViewModel()

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

    public var body: some View {
        if viewModel.isFailure {
            errorView
        } else {
            HubspotChatWebView(manager: manager,
                               pushData: pushData,
                               chatFlow: chatFlow,
                               viewModel: viewModel)
                .overlay(content: {
                    loadingView
                })
        }
    }

    @ViewBuilder
    var loadingView: some View {
        if viewModel.loading {
            ProgressView()
                .progressViewStyle(.circular)
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    var errorView: some View {
        if let configError = viewModel.configError {
            switch configError {
            case .missingChatFlow:
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("Missing Chat Flow", systemImage: "questionmark.bubble")
                } else {
                    // Fallback on earlier versions
                    ContentUnavailableViewCompat("Missing Chat Flow", systemImage: "questionmark.bubble")
                }
            case .missingConfiguration:
                if #available(iOS 17.0, *) {
                    ContentUnavailableView("Missing Configuration", systemImage: "gear.badge.questionmark")
                } else {
                    ContentUnavailableViewCompat("Missing Configuration", systemImage: "gear.badge.questionmark")
                }
            }
        } else if viewModel.failedToLoadWidget {
            if #available(iOS 17.0, *) {
                ContentUnavailableView("Failed to load chat", systemImage: "network.slash")
            } else {
                ContentUnavailableViewCompat("Failed to load chat", systemImage: "network.slash")
            }
        }
    }
}

/// This is the WebView used witin the chat view - its wrapped with ``HubspotChatView`` incase we need to overlay or inline any errors or loading indicators
struct HubspotChatWebView: UIViewRepresentable {
    public typealias UIViewType = WKWebView

    private let manager: HubspotManager
    private let chatFlow: String?
    private let pushData: PushNotificationChatData?

    // Note - not a state , or observed object - we don't need to monitor it here
    let viewModel: ChatViewModel

    /// Create the chat view, optionally specifying the HubspotManager and Chat Flow to use.
    ///
    /// > Info: chatFlow may only take effect if a valid user identity is configured. See ``HubspotManager/setUserIdentity(identityToken:email:)``
    ///
    /// - Parameters:
    ///   - manager: manager to use when creating urls for account and getting user properties
    ///   - pushData: Struct containing any of the hubspot values from the push body payload.
    ///   - chatFlow: The specific chat flow to open, if any
    init(manager: HubspotManager,
         pushData: PushNotificationChatData?,
         chatFlow: String?,
         viewModel: ChatViewModel)
    {
        self.manager = manager
        self.chatFlow = chatFlow
        self.pushData = pushData
        self.viewModel = viewModel
    }

    func makeCoordinator() -> WebviewCoordinator {
        return WebviewCoordinator(manager: manager, viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
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

        #if DEBUG
            // This allows safari
            if #available(iOS 16.4, *) {
                webview.isInspectable = true
            }
        #endif

        webview.isOpaque = false
        webview.backgroundColor = UIColor.systemBackground
        webview.navigationDelegate = context.coordinator
        webview.uiDelegate = context.coordinator

        // Its likely safe to trigger this from here - if we are preparing our ui for chat, likelihood is we will soon have an id and need to report properties.
        manager.prepareForPotentialChat()

        return webview
    }

    /// This will load the chat url in the website, if available. Called automatically.
    func updateUIView(_ webView: WKWebView, context: Context) {
        do {
            /// If we have already failed to load the widget, we don't want to try again - what happens is as the webview isn't loaded, it triggers the update view, attempts to load fails, the view reloads, thinks it needs to update, and repeats
            guard !viewModel.failedToLoadWidget else {
                return
            }

            let urlToLoad = try manager.chatUrl(withPushData: pushData, forChatFlow: chatFlow)
            let request = URLRequest(url: urlToLoad)

            Task {
                await viewModel.didStartLoading()
            }
            // Debugging delay to attach safari debugger

            let mainLoadNavReference = webView.load(request)
            context.coordinator.mainLoadNavReference = mainLoadNavReference

        } catch {
            DispatchQueue.main.async {
                viewModel.setError(error)
            }
            manager.logger.error("Unable to load chat. Webview will be blank. \(error)")
        }
    }

    /// The coordinator helps with the Swift View to UIView lifecycle , and stays alive (along with the UIKit views)  when the swift view itself may be recreated.
    /// This is the sensible place for our delegate callbacks
    class WebviewCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let viewModel: ChatViewModel
        let manager: HubspotManager

        init(manager: HubspotManager, viewModel: ChatViewModel) {
            self.manager = manager
            self.viewModel = viewModel
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
            } else if (Array.isArray(window.hsConversationsOnReady)) {
                window.hsConversationsOnReady.push(configureHubspotConversations);
            } else {
                window.hsConversationsOnReady = [configureHubspotConversations];
            }

            window.webkit.messageHandlers.nativeApp.postMessage({ "info": "finished main load script" });
            """

            contentController.addUserScript(WKUserScript(source: configCallbacksJS, injectionTime: .atDocumentEnd, forMainFrameOnly: false))
        }

        func webView(_: WKWebView, didCommit navigation: WKNavigation!) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                Task {
                    await viewModel.didStartLoading()
                }
                // create script that triggers on hubspot event, and calls our message handler
                // Set earlier currently, but might need to move back there
            }
        }

        func webView(_: WKWebView, didFinish navigation: WKNavigation!) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                Task {
                    await self.viewModel.didLoadUrl()
                }
                // create script that triggers on hubspot event, and calls our message handler
                // Set earlier currently, but might need to move back there
            }
        }

        func webView(_: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                Task {
                    await self.viewModel.didFailToLoadUrl(error: error)
                }
            }
        }

        func webView(_: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
            let isMain = navigation == mainLoadNavReference

            if isMain {
                Task {
                    await self.viewModel.didFailToLoadUrl(error: error)
                }
            }
        }

        func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any] {
                /// this message is sent on widget loading
                if let message = dict["message"] as? String, message == "widget has loaded" {
                    Task {
                        await viewModel.didLoadWidget()
                    }
                }

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

/// We use this to hold a loading state - using a state & binding into the web view represetable causes some infinte loading to occur
/// May migrate more functionality that was direct to manager here in future
@MainActor
class ChatViewModel: ObservableObject {
    @Published private(set) var loading: Bool = false

    var failedToLoadWidget = false

    /// used to show error instead of chat view webview
    var isFailure: Bool {
        // TODO: - add generic error also?
        return configError != nil || failedToLoadWidget
    }

    @Published var configError: HubspotConfigError?

    /// Call when we are going to load the widget embed url
    func didStartLoading() async {
        // Reset and update loading flags,  but only if set to avoid unneeded mutations
        if failedToLoadWidget {
            failedToLoadWidget = false
        }

        if !loading {
            loading = true
        }
    }

    /// Call when url is loaded - we may or may not want to consider this the final step
    func didLoadUrl() async {
        if loading {
            loading = false
        }
    }

    func didFailToLoadUrl(error: Error) async {
        if let urlError = error as? URLError {
            switch urlError.code {
            case URLError.cancelled:
                // ignore cancels as they can trigger during retry I believe
                break
            default:
                // All other cases, consider the widget not loaded
                if !failedToLoadWidget {
                    failedToLoadWidget = true
                }
            }
        }

        if loading {
            loading = false
        }
    }

    /// Call when the widget emits a loaded message - this might be our indication that the widget has loaded at all
    func didLoadWidget() async {
        // nothing - removing our custom error display as there's one as part of the widget now
    }

    func setError(_ error: Error) {
        guard let hsError = error as? HubspotConfigError else {
            return
        }

        configError = hsError
    }
}

/// Something similar to content unavailable, doesn't need to be exact - ideally end user never has configuration issues that cause these to show by release
private struct ContentUnavailableViewCompat: View {
    let message: LocalizedStringKey
    let systemImage: String
    var body: some View {
        // Stack is here as modifiers complained about view type otherwise
        VStack(spacing: 8) {
            Text("\(Image(systemName: systemImage))")
                .font(.title)
                .bold()
                .foregroundStyle(.secondary)

            Text(message).bold()
                .font(.title2)
        }

        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity, alignment: .center)
    }

    init(_ message: LocalizedStringKey, systemImage: String) {
        self.message = message
        self.systemImage = systemImage
    }
}

#Preview {
    ContentUnavailableViewCompat("Failed to load chat", systemImage: "network.slash")
}
