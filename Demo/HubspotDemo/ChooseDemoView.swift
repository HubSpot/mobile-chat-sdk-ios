// ChooseDemoView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI
import UserNotifications

struct ChooseDemoView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State var showDebugOptions: Bool = false

    /// This is set from listening to incoming opening pushes from the notification delegate
    @State var showChatFromPushNotification = false
    @State var selectedChatData: PushNotificationChatData? = nil

    /// Just an example of how an notification may have its own handling
    @State var showAppFeatureFromPushNotification = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ChatFromCustomButton(), label: {
                        Text("Custom buttons")

                    })

                    NavigationLink(destination: FloatingExamplesListView(), label: {
                        Text("Floating button examples")
                    })

                    NavigationLink(destination: ToolBarExamplesListView(), label: {
                        Text("Nav bars & toolbars")
                    })

                    NavigationLink(destination: SpecificChatFlowView(), label: {
                        Text("Specific chat flow")
                    })
                }
                Section {
                    NavigationLink(destination: CustomPropertiesListView(), label: {
                        Text("Custom Properties")
                    })
                }

                Section {
                    NavigationLink(destination: NotificationsView(), label: {
                        Text("Notifications")
                    })
                }
            }
            .navigationTitle("Hubspot Demo")
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(action: {
                        withAnimation {
                            showDebugOptions = true
                        }
                    }, label: {
                        Image(systemName: "gearshape.fill")
                    })
                })
            })
            .sheet(isPresented: $showDebugOptions, content: {
                SDKOptionsView()
            })
            .fullScreenCover(isPresented: $appViewModel.hubspotSdkFailure, content: {
                sdkSetupFailureView
                    .padding()
            }).sheet(isPresented: $showChatFromPushNotification, content: {
                // Here, we are using a sheet over our initial content ui - but this might be best somewhere else in your own app struture, depending on how your root view is managed.
                HubspotChatView(manager: HubspotManager.shared, pushData: selectedChatData)
            })
            .sheet(isPresented: $showAppFeatureFromPushNotification, content: {
                DemoPlaceholderFeatureView()
            })
            .onReceive(appViewModel.notificationDelegate.$selectedAppNotification, perform: handleAppNotificationsNotForChat)
            .onReceive(appViewModel.notificationDelegate.$selectedChatNotification, perform: handleUserSelectingChatNotification)
        }
    }

    var sdkSetupFailureView: some View {
        VStack {
            Text("Config Issue")
                .font(.title)
            Divider()
            Text("The demo app had issues setting up. Please check the logs to correct. Perhaps config file was altered or deleted?")
            if let hubspotError = appViewModel.hubspotError {
                Text(hubspotError.localizedDescription)
                    .padding()
                    .italic()
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.secondary)
                    .background(Color(.secondarySystemBackground))
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    func handleAppNotificationsNotForChat(_ notification: UNNotification?) {
        guard notification != nil else {
            return
        }
        // For the demo, we just present a screen - but a real app might update content, or trigger a feature
        showAppFeatureFromPushNotification = true
    }

    func handleUserSelectingChatNotification(_ notification: PushNotificationChatData?) {
        // This is one example way to handle notification delegate -> UI , there's many ways to approach it.

        guard let notification
        else {
            return
        }

        // If we aren't already showing a chat, show one, if we are, do nothing.
        if !showChatFromPushNotification {
            selectedChatData = notification
            showChatFromPushNotification = true
        }
    }
}

struct FloatingExamplesListView: View {
    var floatingExampleWithBar: some View {
        FloatingButtonExampleContainerView(description: """
            This example shows the floating button used in a view with a standard toolbar configured - the buttons in the toolbar do nothing. The floating chat button avoids the bar.
            """
        ).navigationTitle("Floating button (with bar)")
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button("Button 1", action: {})
                    Button("Button 2", action: {})
                    Button("Button 3", action: {})
                }
            }
    }

    var body: some View {
        List {
            NavigationLink(destination: FloatingButtonExampleContainerView(description: """
                This example shows the chat button without any tabs - the button doesn't have to be in a navigation component, as it presents its content modally
                """
            ), label: {
                Text("Floating button")
            })

            NavigationLink(destination: floatingExampleWithBar, label: {
                Text("Floating button (with bar)")
            })

            NavigationLink(destination: FloatingButtonModifierView(), label: {
                Text("Floating button (view modifier)")
            })

            NavigationLink(destination: TabBarWithGlobalFloatingButton(), label: {
                Text("Tabs + Floating button (global)")
            })

            NavigationLink(destination: TabBarWithIndividualFloatingButton(), label: {
                Text("Tabs + Floating button (single tabs)")
            })
        }
        .navigationTitle("Floating Button Examples")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ToolBarExamplesListView: View {
    var body: some View {
        List {
            NavigationLink(destination: NavToolbarWithChatButtonView(), label: {
                Text("Nav bar button")
            })

            NavigationLink(destination: ToolbarWithChatButtonView(), label: {
                Text("toolbar button")
            })
        }
    }
}

#Preview("Choose Demo") {
    ChooseDemoView()
        .setPreviewEnvironment()
}

#Preview("Floating list") {
    NavigationStack {
        FloatingExamplesListView()
    }
}

#Preview("Toolbar List") {
    NavigationStack {
        ToolBarExamplesListView()
    }
}

extension View {
    func setPreviewEnvironment() -> some View {
        environmentObject(AppViewModel()).environmentObject(DemoAppDelegate())
    }
}
