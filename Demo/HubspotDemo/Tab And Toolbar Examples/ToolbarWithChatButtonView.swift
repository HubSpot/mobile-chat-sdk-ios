// ToolbarWithChatButtonView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct ToolbarWithChatButtonView: View {
    @State var showingChat = false

    var body: some View {
        ScrollView {
            VStack {
                Text(
                    """
                    This content screen has a chat button placed in a tool bar - another option for when overlaying a larger chat button over content isn't ideal - SwiftUI determines the sizing and layout of the toolbar.

                    The button here is just a standard, plain button with text.
                    """).multilineTextAlignment(.leading)
                    .padding(.vertical)
                PlaceholderView()
            }
            .padding()
        }
        .navigationTitle("My Content")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar, content: {
                Button(action: showChat) {
                    Text("Chat with us")
                }
            })
        }
        .sheet(isPresented: $showingChat, content: {
            HubspotChatView()
        })
    }

    func showChat() {
        showingChat = true
    }
}

#Preview {
    NavigationStack {
        ToolbarWithChatButtonView()
    }
}
