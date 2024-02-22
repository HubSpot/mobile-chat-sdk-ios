// FloatingButtonModifierView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

/// The simpliest way to add the floating button, using convenience modifier to overlay in the bottom corner
struct FloatingButtonModifierView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Example using a view modifier function to include the button")

                Divider()
                placeholderText
                Divider()
                placeholderText
                Spacer()
            }.padding()
        }
        .navigationTitle("Floating Button (modifier)")
        .overlayHubspotFloatingActionButton()
    }

    var placeholderText: some View {
        Text("placeholder.text").redacted(reason: .placeholder)
    }
}

#Preview {
    FloatingButtonModifierView()
}
