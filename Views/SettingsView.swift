import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Search") {
                    Picker("Search Engine", selection: Binding(
                        get: { appState.preferences.searchEngine },
                        set: { appState.preferences.searchEngine = $0; appState.savePreferences() }
                    )) {
                        ForEach(SearchEngine.allCases) { engine in
                            Text(engine.rawValue).tag(engine)
                        }
                    }

                    TextField("Homepage", text: Binding(
                        get: { appState.preferences.homepage },
                        set: { appState.preferences.homepage = $0; appState.savePreferences() }
                    ))
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                }

                Section("Privacy") {
                    Toggle("Content Blocker", isOn: Binding(
                        get: { appState.preferences.contentBlockerEnabled },
                        set: {
                            appState.preferences.contentBlockerEnabled = $0
                            appState.savePreferences()
                            if $0 { PrivacyManager.shared.compileContentBlockerRules() }
                        }
                    ))

                    Toggle("HTTPS-Only Mode", isOn: Binding(
                        get: { appState.preferences.httpsOnlyMode },
                        set: { appState.preferences.httpsOnlyMode = $0; appState.savePreferences() }
                    ))

                    Toggle("Auto-Clear on Quit", isOn: Binding(
                        get: { appState.preferences.autoClearOnQuit },
                        set: { appState.preferences.autoClearOnQuit = $0; appState.savePreferences() }
                    ))

                    Button("Clear All Browsing Data", role: .destructive) {
                        PrivacyManager.shared.clearBrowsingData()
                    }

                    Button("Clear History", role: .destructive) {
                        appState.history.removeAll()
                        appState.persistState()
                    }
                }

                Section("Display") {
                    Toggle("Show Start Page", isOn: Binding(
                        get: { appState.preferences.startPageEnabled },
                        set: { appState.preferences.startPageEnabled = $0; appState.savePreferences() }
                    ))

                    Stepper(
                        "Suspend tabs after \(appState.preferences.tabSuspensionMinutes) min",
                        value: Binding(
                            get: { appState.preferences.tabSuspensionMinutes },
                            set: { appState.preferences.tabSuspensionMinutes = $0; appState.savePreferences() }
                        ),
                        in: 1...60
                    )
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Built by")
                        Spacer()
                        Text("Joshua Trommel")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
