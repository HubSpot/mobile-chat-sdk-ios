// TabBarWithGlobalFloatingButton.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

/// This is an example of positioning the floating action button over a tab view, aligned with the tab contents, using achors to avoid making assumptions about bar sizes
struct TabBarWithGlobalFloatingButton: View {
    var body: some View {
        TabView {
            tab1view
                .tabItem {
                    Label("Tab 1", systemImage: "lamp.table.fill")
                }
                .anchorPreference(key: FloatingButtonAlignmentPreferenceKey.self, value: .bottomTrailing, transform: { anchor in
                    return anchor
                })

            tab2view
                .tabItem {
                    Label("Tab 2", systemImage: "fanblades.fill")
                }
                .anchorPreference(key: FloatingButtonAlignmentPreferenceKey.self, value: .bottomTrailing, transform: { anchor in
                    return anchor
                })

            tab3view
                .tabItem {
                    Label("Tab 3", systemImage: "light.cylindrical.ceiling.inverse")
                }
                .anchorPreference(key: FloatingButtonAlignmentPreferenceKey.self, value: .bottomTrailing, transform: { anchor in
                    return anchor
                })
        }
        .overlayPreferenceValue(FloatingButtonAlignmentPreferenceKey.self) { value in
            GeometryReader { proxy in
                if let value {
                    let y = proxy[value].y
                    let x = proxy[value].x

                    // x and y is the bottom corner of the tab content, because we put the anchor preference on the tab - if we just use x&y as a position or offset then the _center_ of the button would be in the corner so wrap in a frame that size so button can be aligned to bottom corner of this new space, limited by the anchor

                    FloatingActionButton()
                        .padding()
                        .frame(width: x, height: y, alignment: .bottomTrailing)
                }
            }
        }
    }

    struct FloatingButtonAlignmentPreferenceKey: PreferenceKey {
        typealias Value = Anchor<CGPoint>?

        static let defaultValue: Anchor<CGPoint>? = .none

        static func reduce(value: inout Anchor<CGPoint>?, nextValue: () -> Anchor<CGPoint>?) {
            if let nextValue = nextValue() {
                value = nextValue
            }
        }
    }

    var tab1view: some View {
        ScrollView {
            VStack {
                Text("""
                    This is tab 1.

                    These tabs are all their own views, but the button is independent of the tab contents, floating above it using overlays
                    """
                )
                .frame(maxWidth: .infinity)
                PlaceholderView()
                Divider()
                PlaceholderView()
                Spacer()
            }
            .padding(.horizontal)
        }
    }

    var tab2view: some View {
        ScrollView {
            VStack {
                Text("This is tab 2")
                    .frame(maxWidth: .infinity)
                PlaceholderView()
                Divider()
                PlaceholderView()
                Spacer()
            }.padding(.horizontal)
        }.background(.green)
    }

    var tab3view: some View {
        ScrollView {
            VStack {
                Text("This is tab 3")
                    .frame(maxWidth: .infinity)
                PlaceholderView()
                Divider()
                PlaceholderView()
                Spacer()
            }.padding(.horizontal)
        }.background(.yellow)
    }
}

#Preview {
    TabBarWithGlobalFloatingButton()
}
