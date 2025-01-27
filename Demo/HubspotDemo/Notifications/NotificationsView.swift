// NotificationsView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var appDelegate: DemoAppDelegate
    @EnvironmentObject var appViewModel: AppViewModel

    @State var notificationCentrePermission: Bool = false
    @State var notificationAlertPermission: Bool = false

    @State var taskCounter = 0

    var body: some View {
        ScrollView {
            VStack {
                Text("Recent Pushes")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Counters incrementing when app delegate gets a push received callback, just to help test regular pushes vs pushes containing hubspot keys / data")

                pushGridView

                Divider()

                Text("Async Task triggered for opening \(taskCounter) times")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .task {
                        for await _ in HubspotManager.shared.newMessages() {
                            taskCounter += 1
                        }
                    }

                Divider()

                Text("Configuration")
                    .font(.title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    remoteEnableSettings
                    provisionalSettings
                    alertSettings
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(6)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Notifications")
        .task {
            await checkPermissions()
        }
    }

    var pushGridView: some View {
        Grid(alignment: .leading) {
            GridRow {
                Text("Notifications received")
                    .bold()
                    .gridCellColumns(2)

            }.background(Color(uiColor: .secondarySystemBackground))

            GridRow {
                Text("all")
                    .bold()

                Text("hubspot")
                    .bold()
            }

            GridRow {
                Text(String(appDelegate.countOfpushesReceived + appViewModel.notificationDelegate.countOfpushesReceived))

                Text(String(appDelegate.countOfHubspotPushesReceived + appViewModel.notificationDelegate.countOfHubspotPushesReceived))
            }

            GridRow {
                Text("Notifications opened")
                    .bold()
                    .gridCellColumns(2)

            }.background(Color(uiColor: .secondarySystemBackground))

            GridRow {
                Text("all")
                    .bold()

                Text("hubspot")
                    .bold()
            }

            GridRow {
                Text(String(appViewModel.notificationDelegate.countOfpushesOpened))

                Text(String(appViewModel.notificationDelegate.countOfHubspotPushesOpened))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical)
    }

    var tokenDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }

    var remoteEnableSettings: some View {
        VStack {
            Text("Just register for remote push itself, and see the token.")

            Button("Register for remote push") {
                appViewModel.registerForPush()
            }

            if let token = appDelegate.deviceToken,
                let tokenDate = appDelegate.tokenDate
            {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Token\nlast checked:\n\(tokenDate, formatter: tokenDateFormatter)")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(token.toHexString())
                        .monospaced()
                        .font(.system(size: 14))
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                }.frame(maxWidth: .infinity)
            }
        }
    }

    var provisionalSettings: some View {
        VStack {
            Text("Enable provisional notifications without asking for permission.\n\nThis will allow notifications straight to notification centre")
            if !notificationCentrePermission {
                Button("Enable Provisional Notifications") {
                    Task {
                        do {
                            try await UNUserNotificationCenter.current().requestAuthorization(options: [.provisional])
                            await checkPermissions()
                        } catch {
                            logger.error("Error enabling provisional notifications in demo app: \(error)")
                        }
                    }
                }
            } else {
                Divider()
                Text("Permission exists to show notification centre notifications already")
                    .padding()
                    .italic()
            }
        }
    }

    var alertSettings: some View {
        VStack {
            Text("Enable regular notifications (alert, sound, badge) - this will show user alert on first use")
            if !notificationAlertPermission {
                Button("Enable Alerts") {
                    Task {
                        do {
                            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                            await checkPermissions()
                        } catch {
                            logger.error("Error enabling normal notifications in demo app: \(error)")
                        }
                    }
                }
            } else {
                Divider()
                Text("Permission exists to show alerts already")
                    .padding()
                    .italic()
            }
        }
    }

    @MainActor func checkPermissions() async {
        // UNUserNotificationCenter is not sendable, resulting in error sending from nonisolated to the main actor, so need to use non isolated task to find value, then pass basic bools back to main actor to update view properties - seems a bit overkill just to access notification center from something as common as main actor isolated code - possibly will be fixed in future versions of tools?

        Task.detached {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let notificationCentrePermission = settings.notificationCenterSetting == .enabled
            let notificationAlertPermission = settings.alertSetting == .enabled

            Task { @MainActor in
                self.notificationAlertPermission = notificationAlertPermission
                self.notificationCentrePermission = notificationCentrePermission
            }
        }
    }
}

#Preview {
    NotificationsView()
        .setPreviewEnvironment()
}
