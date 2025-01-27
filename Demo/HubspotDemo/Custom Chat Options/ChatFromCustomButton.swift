// ChatFromCustomButton.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2025 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct ChatFromCustomButton: View {
    @State var showChat = false
    @State var showChatFullscreen = false

    var body: some View {
        ScrollView {
            VStack {
                Text(
                    """
                    Use these regular buttons to start a chat. This button styling isn't from the SDK, but contained within the demo app, to show that any sort of custom styling could be used on a button that shows the chat view.

                    This set of buttons also show the different iOS navigation patterns - modal , full screen, and pushed onto navigation stack.
                    """
                ).padding()

                VStack {
                    Button(
                        action: {
                            showChat.toggle()
                        },
                        label: {
                            Text("\(Image(systemName: "message.badge.circle.fill")) Chat Now (sheet/modal)")
                        }
                    ).sheet(
                        isPresented: $showChat,
                        content: {
                            HubspotChatView(manager: HubspotManager.shared)
                        }
                    )

                    Button(
                        action: {
                            showChatFullscreen.toggle()
                        },
                        label: {
                            Text("\(Image(systemName: "message.badge.circle.fill")) Chat Now (fullscreen)")
                        }
                    ).fullScreenCover(
                        isPresented: $showChatFullscreen,
                        content: {
                            NavigationStack {
                                HubspotChatView()
                                    .toolbar {
                                        ToolbarItem(placement: .topBarTrailing) {
                                            Button(action: {
                                                showChatFullscreen = false  // Dismiss the full-screen view
                                            }) {
                                                Text("Close")
                                            }
                                        }
                                    }
                            }
                        }
                    )

                    NavigationLink(
                        destination: HubspotChatView(),
                        label: {
                            Text("\(Image(systemName: "message.badge.circle.fill")) Chat Now (pushed)")
                        }
                    )

                }.padding(.horizontal)
                    .buttonStyle(DemoButtonStyle())
            }
        }
        .navigationTitle("Custom Button Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DemoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.accent)
            )
    }
}

#Preview {
    NavigationStack {
        ChatFromCustomButton()
    }
}
