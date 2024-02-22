// CustomPropertiesListView.swift
// Hubspot Mobile SDK Demo Application
//
// Copyright © 2024 Hubspot, Inc.

import SwiftUI

struct CustomPropertiesListView: View {
    @EnvironmentObject var appModel: AppViewModel

    @State var newKey: String = ""
    @State var newValue: String = ""

    var body: some View {
        VStack {
            List {
                Section(header: headerView,
                        footer: footerView)
                {
                    Text("Keys and values entered here are included in the custom chat properties via HubspotManager when opening chat")
                        .font(.body)

                    ForEach(appModel.customProperties) { property in
                        HStack {
                            Text(property.key)
                                .bold()
                            Spacer()
                            Text(property.value)
                        }
                    }.onDelete(perform: { indexSet in
                        appModel.customProperties.remove(atOffsets: indexSet)
                    })
                }
            }.listStyle(.insetGrouped)

        }.navigationTitle("Custom Properties")
    }

    var headerView: some View {
        Text("\(appModel.customProperties.count) custom keys configured")
    }

    var footerView: some View {
        VStack {
            TextField("Key", text: $newKey)
            TextField("Value", text: $newValue)

            Button(action: {
                appModel.addCustomProperty(key: newKey,
                                           value: newValue)
                newKey = ""
                newValue = ""
            }, label: {
                // Custom label as button was too small
                Text("Add")
                    .frame(maxWidth: .infinity)
            })
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical)
        .textFieldStyle(.roundedBorder)
        .autocorrectionDisabled()
        .autocapitalization(.none)
    }
}

#Preview {
    NavigationStack {
        CustomPropertiesListView()
    }
    .setPreviewEnvironment()
}
