// TabBarWithIndividualFloatingButton.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

/// This is an example of positioning the floating action button with tabs - but the chat button is only on specific tabs - this is achieved by having the button on the content of the tab instead
struct TabBarWithIndividualFloatingButton: View {
    var body: some View {
        TabView {
            tab1view
                .tabItem {
                    Label("Details", systemImage: "lamp.table.fill")
                }

            tab2view
                .tabItem {
                    Label("News", systemImage: "fanblades.fill")
                }
                .overlay(alignment: .bottomLeading) {
                    // This one is 'outside' the tab itself, to avoid modifying the tab view
                    FloatingActionButton()
                        .tint(.yellow)
                        .padding()
                }

            // But here, unlike tab2, the chat button in tab 3 is within the view itself
            tab3view
                .tabItem {
                    Label("Support", systemImage: "light.cylindrical.ceiling.inverse")
                }
        }
    }

    var tab1view: some View {
        ScrollView {
            VStack {
                Text("This is tab 1")
                    .frame(maxWidth: .infinity)
                Divider()
                Text(
                    """
                    No chat button here -> look in tab 3.

                    These tabs are individual views - this time there's no global chat button over all the tabs, instead each tab is deciding if it wants a button and deciding where it goes.

                    Tab 2 and 3 intentionally have different button placements as an example

                    """)
                PlaceholderView()
                Divider()
                Text("No chat button here -> look in tab 3")
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
        }
        .background(.green.opacity(0.2))
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
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingActionButton()
                .padding()
        }
        .background(.yellow.opacity(0.2))
    }
}

#Preview {
    TabBarWithIndividualFloatingButton()
}
