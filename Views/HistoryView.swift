import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredHistory: [HistoryEntry] {
        if searchText.isEmpty {
            return Array(appState.history.prefix(100))
        }
        let lowered = searchText.lowercased()
        return appState.history.filter {
            $0.title.lowercased().contains(lowered) || $0.url.absoluteString.lowercased().contains(lowered)
        }.prefix(100).map { $0 }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredHistory) { entry in
                    Button {
                        appState.openInSelectedTab(entry.url)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .lineLimit(1)
                            HStack {
                                Text(entry.url.host ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(entry.visitDate, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search history")
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear", role: .destructive) {
                        appState.history.removeAll()
                        appState.persistState()
                    }
                }
            }
        }
    }
}
