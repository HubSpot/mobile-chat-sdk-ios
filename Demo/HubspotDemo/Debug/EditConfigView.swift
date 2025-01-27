// EditConfigView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct EditConfigView: View {
    @Environment(\.dismiss) var dismiss

    @State var enteredPortalId: String = ""
    @State var enteredHublet: String = ""
    @State var selectedEnvironment: HubspotEnvironment = .production
    @State var enteredDefaultChatFlow: String = ""

    @State var showReset = false

    /// True when the state variables differ from the current values
    var hasChanges: Bool {
        let portalMatches = enteredPortalId.trimmingCharacters(in: .whitespacesAndNewlines) != HubspotManager.shared.portalId
        let hubletMatches = enteredHublet.trimmingCharacters(in: .whitespacesAndNewlines) != HubspotManager.shared.hublet
        let flowMatches = enteredDefaultChatFlow.trimmingCharacters(in: .whitespacesAndNewlines) != HubspotManager.shared.defaultChatFlow
        let envMatches = selectedEnvironment == HubspotManager.shared.environment

        return !portalMatches || !hubletMatches || !flowMatches || !envMatches
    }

    var body: some View {
        VStack {
            List {
                Section {
                    TextField("Portal ID", text: $enteredPortalId)
                    TextField("Hublet", text: $enteredHublet)
                    TextField("Chat Flow", text: $enteredDefaultChatFlow)
                    Picker(
                        "Environment", selection: $selectedEnvironment,
                        content: {
                            Text("Production")
                                .tag(HubspotEnvironment.production)
                            Text("QA")
                                .tag(HubspotEnvironment.qa)
                        }
                    ).pickerStyle(.segmented)
                    Button(
                        action: saveChanges,
                        label: {
                            Label("Save Config", systemImage: "slider.horizontal.3")
                        }
                    ).disabled(!hasChanges)
                }
                Section {
                    Text("Clear any edited values previously saved, and go back to using the bundled config values")
                    Button(
                        role: .destructive, action: { showReset = true },
                        label: {
                            Label("Reset to default", systemImage: "minus.square")
                        }
                    )
                    .confirmationDialog("Reset Config", isPresented: $showReset) {
                        Button("Reset", role: .destructive, action: resetConfig)
                    }
                }

                Section {
                    Text("Note: Editing the config during runtime may result in some inconsistent behaviour after editing. Fully stopping the app via multi tasker and relaunching may be a convenient way to reset any inconsistent behaviour due to run time config changes.")
                        .font(.callout)
                }
            }.onAppear(perform: setInitialValues)
        }
        .navigationTitle("Edit Config")
    }

    func setInitialValues() {
        enteredPortalId = HubspotManager.shared.portalId ?? ""
        enteredHublet = HubspotManager.shared.hublet ?? ""
        selectedEnvironment = HubspotManager.shared.environment
        enteredDefaultChatFlow = HubspotManager.shared.defaultChatFlow ?? ""
    }

    func saveChanges() {
        guard hasChanges else {
            return
        }

        let enteredPortalId = enteredPortalId.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredHublet = enteredHublet.trimmingCharacters(in: .whitespacesAndNewlines)
        let enteredDefaultChatFlow = enteredDefaultChatFlow.trimmingCharacters(in: .whitespacesAndNewlines)

        UserDefaults.standard[.overridePortalId] = enteredPortalId
        UserDefaults.standard[.overrideHublet] = enteredHublet
        UserDefaults.standard[.overrideEnv] = selectedEnvironment.rawValue
        UserDefaults.standard[.overrideDefaultChatFlow] = enteredDefaultChatFlow

        logger.trace("Updating configuration on shared manager")
        HubspotManager.configure(
            portalId: enteredPortalId,
            hublet: enteredHublet,
            defaultChatFlow: enteredDefaultChatFlow,
            environment: selectedEnvironment)

        dismiss()
    }

    func resetConfig() {
        UserDefaults.standard.removeObject(forStorageKey: .overridePortalId)
        UserDefaults.standard.removeObject(forStorageKey: .overrideHublet)
        UserDefaults.standard.removeObject(forStorageKey: .overrideEnv)
        UserDefaults.standard.removeObject(forStorageKey: .overrideDefaultChatFlow)

        logger.trace("Triggering initial configure call")
        try? HubspotManager.configure()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditConfigView()
    }
}
