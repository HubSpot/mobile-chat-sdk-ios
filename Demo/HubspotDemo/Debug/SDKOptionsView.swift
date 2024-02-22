// SDKOptionsView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import Foundation
import HubspotMobileSDK
import SwiftUI

struct SDKOptionsView: View {
    let ENABLE_IDENTITY_TOKEN_CREATION = false

    @Environment(\.dismiss)
    var dismiss

    @State var showIdInput = false
    @State var configUserIdentity = false

    @State var errorCreatingToken: String? = nil
    @State var isCreatingToken = false

    @AppStorage("idToken") var inputtedToken = ""
    @AppStorage("userEmail") var inputtedEmail = ""

    // Warning: Do not store app access token in a publicly acessible app
    @AppStorage("accessToken") var accessToken = ""
    @AppStorage("enteredFirstName") var createTokenFirstName = ""
    @AppStorage("enteredLastName") var createTokenLastName = ""
    @AppStorage("enteredEmail") var createTokenEmail = ""

    @ObservedObject var manager: HubspotManager

    init(manager: HubspotManager = .shared) {
        self.manager = manager
    }

    var body: some View {
        NavigationStack {
            List {
                currentConfigSection
                userIdentitySection
                loggingSection
            }
            .navigationDestination(
                isPresented: $configUserIdentity,
                destination: {
                    userIdentityView
                }
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(action: { dismiss() },
                           label: {
                               Text("Close")
                           })
                })
            }
            .navigationTitle("SDK Options")
        }
    }

    @ViewBuilder
    var currentConfigSection: some View {
        Section("Current Config") {
            detailRow(label: "Portal ID", value: manager.portalId ?? "<Not Available>")
            detailRow(label: "Hublet", value: manager.hublet ?? "<Not Available>")
            detailRow(label: "Environment", value: manager.environment.description)
            detailRow(label: "Default Chat Flow", value: manager.defaultChatFlow ?? "<Not Available>")
        }
    }

    @ViewBuilder
    var userIdentitySection: some View {
        Section("User Identity") {
            if let token = manager.userIdentityToken, let email = manager.userEmailAddress {
                detailRow(label: "Token", value: token)
                detailRow(label: "Email", value: email)
            } else {
                Text("Not set")
                    .italic()
            }
            Button("Configure") {
                configUserIdentity = true
            }
        }
    }

    @ViewBuilder
    var loggingSection: some View {
        Section("Logging") {
            Button(action: {
                HubspotManager.shared.debug_emitSomeLogs()
            }, label: {
                Text("Emit Some Logs")
            })

            Button(action: {
                HubspotManager.shared.disableLogging()
            }, label: {
                Text("Disable Logging")
            })

            Button(action: {
                HubspotManager.shared.enableLogging()
            }, label: {
                Text("Enable Logging")
            })
        }
    }

    // I forget if this is a standard view
    func detailRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    var userIdentityView: some View {
        List {
            Section("Existing token") {
                Text("Copy & paste your user identity token you have generated elsewhere here")
                TextField("Identity token", text: $inputtedToken)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField("Email Address", text: $inputtedEmail)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)

                Button("Apply") {
                    manager.setUserIdentity(identityToken: inputtedToken,
                                            email: inputtedEmail)
                    configUserIdentity = false
                }.disabled(inputtedEmail.isEmpty || inputtedToken.isEmpty)
                Button("Clear data") {
                    inputtedEmail = ""
                    inputtedToken = ""
                    manager.clearUserData()
                    configUserIdentity = false
                }
            }

            if ENABLE_IDENTITY_TOKEN_CREATION {
                // This is a convenience for the sake of demo app , building in token generation that would normally be done
                // on a server as  part of a proper user auth flow perhaps.
                // This just avoids the need to manually run api commands & hard code tokens during early development

                Section("Create Identity Token") {
                    Text("Create a token using the form below if no other method exists to get one")
                    TextField("App Access Token", text: $accessToken)
                    TextField("Email", text: $createTokenEmail)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                    TextField("First name", text: $createTokenFirstName)
                        .textInputAutocapitalization(.never)
                        .textContentType(.givenName)
                    TextField("Last name", text: $createTokenLastName)
                        .textInputAutocapitalization(.never)
                        .textContentType(.familyName)

                    Text("When creating a token below, it will replace/fill the inputted token and email in the first form, apply the token, and close this screen.")

                    Button("Request Token") {
                        createIdentityToken()
                    }.disabled(isCreatingToken)

                    if let error = errorCreatingToken {
                        Text("Error: \(error)")
                            .bold()
                            .padding()
                    } else if isCreatingToken {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }

        }.navigationTitle("User Identity")
    }

    private func createIdentityToken() {
        Task {
            errorCreatingToken = nil
            isCreatingToken = true
            defer {
                self.isCreatingToken = false
            }

            do {
                let token = try await manager.aquireUserIdentityToken(accessToken: accessToken,
                                                                      email: createTokenEmail,
                                                                      firstName: createTokenFirstName,
                                                                      lastName: createTokenLastName)

                if !token.isEmpty, !createTokenEmail.isEmpty {
                    inputtedEmail = createTokenEmail
                    inputtedToken = token

                    try Task.checkCancellation()

                    manager.setUserIdentity(identityToken: token,
                                            email: createTokenEmail)

                    // Brief delay to show the fields updating before screen closes
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    configUserIdentity = false
                } else {
                    errorCreatingToken = "Token or email was empty."
                }
            } catch {
                errorCreatingToken = error.localizedDescription
            }
        }
    }
}

#Preview {
    SDKOptionsView()
}

#Preview {
    NavigationStack {
        Text("Preview")
            .sheet(isPresented: .constant(true), content: {
                SDKOptionsView()
            })
    }
}
