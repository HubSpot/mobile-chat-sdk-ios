// SpecificChatFlowView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import HubspotMobileSDK
import SwiftUI

struct SpecificChatFlowView: View {
    let constantFlow = "mobileflow3"

    @State var enteredChatFlow: String = "mobileflow3"
    @State var presentChatFlowFromField: Bool = false

    var body: some View {
        ScrollView {
            VStack {
                Text("When opening chat view, one can optionally specfiy a chat flow. Here's a way to test that out. One option opens the default chat, based on the bundled configuration. Another opens a fixed flow - set as a constant in code, for example for a specific sub section of your app. And lastly, a dynamic value - perhaps derived from push message, your server back end, or a dynamic config.")
                    .padding(.bottom)

                Divider()

                VStack(alignment: .leading) {
                    Text("Default flow - value taken from initial config: \(HubspotManager.shared.defaultChatFlow ?? "")")
                        .italic()
                    TextChatButton()
                    Divider()

                    Text("Flow for this one is currently set to '\(constantFlow)' - this would be set to whatever id you hardcode in your app")
                        .italic()
                    TextChatButton(chatFlow: constantFlow)
                    Divider()

                    VStack {
                        Text("here, you can enter any chat flow you want, for the configured hubspot portal, perhaps based on your api data")

                        TextField("some chatFlow, ex: sales", text: $enteredChatFlow)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .keyboardType(.asciiCapable)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.go)
                            .onSubmit {
                                let enteredFlow = enteredChatFlow.trimmingCharacters(in: .whitespacesAndNewlines)

                                if !enteredFlow.isEmpty {
                                    presentChatFlowFromField = true
                                }
                            }
                            .sheet(isPresented: $presentChatFlowFromField) {
                                HubspotChatView(chatFlow: enteredChatFlow.trimmingCharacters(in: .whitespacesAndNewlines))
                            }

                        TextChatButton(text: "Start '\(enteredChatFlow.trimmingCharacters(in: .whitespacesAndNewlines))' Chat",
                                       chatFlow: enteredChatFlow.trimmingCharacters(in: .whitespacesAndNewlines))
                    }

                }.ignoresSafeArea([.container])
            }
            .padding()
            .padding(.bottom, 200) // additional spacing at the bottom for overscroll
        }.navigationTitle("Setting Chat Flow")
    }
}

#Preview {
    NavigationStack {
        SpecificChatFlowView()
    }
}
