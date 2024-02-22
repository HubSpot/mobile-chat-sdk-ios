// FloatingButtonExampleContainerView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

/// This shows how to overlay the floating action button in the corners of your content using the overlay modifier
///
struct FloatingButtonExampleContainerView: View {
    let description: LocalizedStringKey

    @State
    var chatAlignment: Alignment = .bottomTrailing

    var body: some View {
        ScrollView {
            VStack {
                Text("This is an example screen")
                    .font(.title)

                Text(description)
                    .padding(.vertical)

                Button("Change position of chat button", action: togglePosition)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical)

                Divider()
                PlaceholderView()
                Divider()
                PlaceholderView()
                Spacer()
            }.padding()
        }
        .navigationTitle("Floating Button")
        .overlay(alignment: chatAlignment) {
            chatOverlay
        }
    }

    func togglePosition() {
        withAnimation {
            switch chatAlignment {
            case .bottomTrailing:
                chatAlignment = .bottomLeading
            case .bottomLeading:
                chatAlignment = .topLeading
            case .topLeading:
                chatAlignment = .topTrailing
            default:
                chatAlignment = .bottomTrailing
            }
        }
    }

    @ViewBuilder
    var chatOverlay: some View {
        FloatingActionButton(manager: HubspotManager.shared)
            .padding()
    }
}

#Preview {
    FloatingButtonExampleContainerView(description: "This is the preview content")
}

#Preview {
    NavigationStack {
        FloatingButtonExampleContainerView(description: "This is the preview content")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Demo 1", action: {})
                    Button("Demo 2", action: {})
                    Button("Demo 3", action: {})
                }
            }
    }
}
