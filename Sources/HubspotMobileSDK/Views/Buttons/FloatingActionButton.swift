// FloatingActionButton.swift
// Hubspot Mobile SDK
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI

/// This is a pre-configured button for opening a chat session. The button manages its own state and presents a ``HubspotChatView`` as a sheet type modal.
///
/// It can be placed anywhere that suits your application, but its ideally intended to be floating in a corner over your main content. You can overlay it however you like, for example using a z-stack or an overlay modifier like so:
/// ```swift
/// content.overlay(alignment: .bottomTrailing, content: {
///    FloatingActionButton()
///     .padding()
/// })
/// ```
///
/// If you want to use a specific chat flow for this part of the application , for example a flow specific to an account section, or support section, you can provide a chat flow id for the button to open:
///
/// ```swift
/// content.overlay(alignment: .bottomLeading) {
///    FloatingActionButton(chatFlow: "marketing")
///       .tint(.yellow)
///       .padding()
/// }
/// ```
///
/// This will overlay the button like this:
/// ![Demo screenshot](floating-button-example-a)
///
/// You can also add the button using the ``overlayHubspotFloatingActionButton(manager:chatFlow:)`` view modifier
///
/// The background color can be customed by setting the accent / tint colour on the view
public struct FloatingActionButton: View {
    private let manager: HubspotManager
    private let chatFlow: String?

    @State var showingChat: Bool = false

    /// Create the button, optionally specifying the chatflow or manager to use.
    /// - Parameters:
    ///   - manager: The manager to use for getting a chat session. By defautl the shared manager is used.
    ///   - chatFlow: The specific chat flow to open. Optional.
    public init(
        manager: HubspotManager? = nil,
        chatFlow: String? = nil
    ) {
        self.manager = manager ?? HubspotManager.shared
        self.chatFlow = chatFlow
    }

    public var body: some View {
        Button(
            action: showChat,
            label: {
                Image(.genericChatIcon)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Circle()
                            .fill()
                    )
            }
        )
        .sheet(
            isPresented: $showingChat,
            content: {
                HubspotChatView(manager: manager, chatFlow: chatFlow)
            }
        )
        .onAppear {
            manager.prepareForPotentialChat()
        }
    }

    func showChat() {
        withAnimation {
            showingChat = true
        }
    }
}

/// Convenient helper for overlaying the action button in the bottom right of a view, with default padding. You can use this directly, but its intended instead to be used with ``overlayHubspotFloatingActionButton(manager:chatFlow:)``
struct FloatingActionButtonOverlayModifier: ViewModifier {
    let manager: HubspotManager
    let chatFlow: String?

    init(manager: HubspotManager? = nil, chatFlow: String? = nil) {
        self.manager = manager ?? HubspotManager.shared
        self.chatFlow = chatFlow
    }

    func body(content: Content) -> some View {
        content.overlay(
            alignment: .bottomTrailing,
            content: {
                FloatingActionButton(manager: manager, chatFlow: chatFlow)
                    .padding()
            }
        )
    }
}

extension View {
    /// Convenience to overlay a floating action button - call on your main content view to overlay button at bottom trailing position with default padding. Set the `chatFlow` property to use a specific flow, otherwise the default flow from your configuration file will be used.
    /// - Parameters:
    ///     - manager: The hubspot manager to use
    ///     - chatFlow: the chat flow targeting parameter to use
    public func overlayHubspotFloatingActionButton(manager: HubspotManager? = nil, chatFlow: String? = nil) -> some View {
        modifier(FloatingActionButtonOverlayModifier(manager: manager, chatFlow: chatFlow))
    }
}

struct ButtonPreviewProvider: PreviewProvider {
    static var previews: some View {
        FloatingActionButton()

        HStack {
            FloatingActionButton()
            FloatingActionButton()
                .tint(.orange)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Colors")
    }
}
