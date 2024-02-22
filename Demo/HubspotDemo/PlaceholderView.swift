// PlaceholderView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI

struct PlaceholderView: View {
    var body: some View {
        Text("placeholder.text").redacted(reason: .placeholder)
    }
}

#Preview {
    PlaceholderView()
}
