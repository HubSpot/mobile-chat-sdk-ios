// NavToolbarWithChatButtonView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct NavToolbarWithChatButtonView: View {
    @State var showingChat = false

    var body: some View {
        ScrollView {
            VStack {
                Text(
                    """
                    This content screen has a chat button placed in the nav bar - an option for when overlaying a larger chat button over content isn't ideal.

                    The button could also be a plain button - here its a custom button style
                    """
                ).multilineTextAlignment(.leading)
                    .padding(.vertical)
                PlaceholderView()
            }
            .padding()
        }
        .navigationTitle("My Content")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing,
                content: {
                    Button(action: showChat) {
                        HStack {
                            Image.hubspotChat
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(.vertical, 5)
                            Text("Chat")
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 3)
                        .background {
                            Capsule()
                                .fill(.accent)
                        }
                        .foregroundColor(.white)
                    }
                })
        }
        .sheet(
            isPresented: $showingChat,
            content: {
                HubspotChatView()
            })
    }

    func showChat() {
        showingChat = true
    }
}

#Preview {
    NavigationStack {
        NavToolbarWithChatButtonView()
    }
}
