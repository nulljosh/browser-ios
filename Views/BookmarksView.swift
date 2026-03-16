import SwiftUI

struct BookmarksView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var folders: [String: [Bookmark]] {
        Dictionary(grouping: appState.bookmarks, by: { $0.folder })
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(folders.keys.sorted(), id: \.self) { folder in
                    Section(folder) {
                        ForEach(folders[folder] ?? []) { bookmark in
                            Button {
                                appState.openInSelectedTab(bookmark.url)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bookmark.title)
                                        .lineLimit(1)
                                    Text(bookmark.url.host ?? bookmark.url.absoluteString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    appState.bookmarks.removeAll { $0.id == bookmark.id }
                                    appState.persistState()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
