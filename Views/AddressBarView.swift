import SwiftUI

struct AddressBarView: View {
    @Bindable var appState: AppState
    @State private var addressText = ""
    @State private var isEditing = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 6) {
            if !isEditing {
                // Lock / security indicator
                if let url = appState.selectedTab?.url {
                    if url.isHTTPS {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.green)
                    } else if url.isHTTP {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }

                Text(displayText)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        addressText = appState.selectedTab?.url.absoluteString ?? ""
                        isEditing = true
                        isFocused = true
                    }

                // Tracker badge
                if let tab = appState.selectedTab, appState.preferences.contentBlockerEnabled {
                    let count = PrivacyManager.shared.trackerCount(for: tab.id)
                    if count > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 9))
                            Text("\(count)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.blue)
                    }
                }

                // Reload / stop
                Button {
                    if appState.selectedTab?.isLoading == true {
                        appState.stopLoading()
                    } else {
                        appState.reload()
                    }
                } label: {
                    Image(systemName: appState.selectedTab?.isLoading == true ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            } else {
                TextField("Search or enter address", text: $addressText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .focused($isFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        appState.showAutocomplete = false
                        appState.navigateCurrent(input: addressText)
                        isEditing = false
                    }
                    .onChange(of: addressText) { _, newValue in
                        appState.updateAutocomplete(query: newValue)
                    }

                Button("Cancel") {
                    isEditing = false
                    isFocused = false
                    appState.showAutocomplete = false
                }
                .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
        .onChange(of: appState.selectedTabID) { _, _ in
            if !isEditing { syncAddressBar() }
        }
        .onChange(of: appState.selectedTab?.url) { _, _ in
            if !isEditing { syncAddressBar() }
        }
    }

    private var displayText: String {
        guard let url = appState.selectedTab?.url else { return "Search or enter address" }
        return url.host ?? url.displayString
    }

    private func syncAddressBar() {
        guard let url = appState.selectedTab?.url else { return }
        addressText = url.absoluteString
    }
}
