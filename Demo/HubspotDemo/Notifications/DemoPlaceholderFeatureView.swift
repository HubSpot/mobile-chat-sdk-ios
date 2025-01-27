// DemoPlaceholderFeatureView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI

struct DemoPlaceholderFeatureView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack {
                Text("Some App Feature").font(.title)
                Text(
                    """
                    This is a placeholder for some feature - that button , or notification might trigger this feature in a real world scenario, rather than hubspot chat.

                    If this placeholder feature appears instead, and you were expecting to see chat view - check the message contents for any missing data keys.
                    """)

                Button("Dismiss") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }.padding()
        }
    }
}

#Preview {
    DemoPlaceholderFeatureView()
}
