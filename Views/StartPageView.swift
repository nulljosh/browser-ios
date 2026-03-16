import SwiftUI

struct StartPageView: View {
    @Environment(AppState.self) private var appState

    private var recentHistory: [HistoryEntry] {
        var seen = Set<String>()
        return appState.history.filter { entry in
            let host = entry.url.host ?? entry.url.absoluteString
            if seen.contains(host) { return false }
            seen.insert(host)
            return true
        }.prefix(8).map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 32)

                Text("Browser")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.primary)

                searchField

                if !appState.bookmarks.isEmpty {
                    bookmarksGrid
                }

                if !recentHistory.isEmpty {
                    recentGrid
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            Text("Search or enter website name")
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        )
    }

    private var bookmarksGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bookmarks")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(appState.bookmarks.prefix(8)) { bookmark in
                    Button {
                        appState.openInSelectedTab(bookmark.url)
                    } label: {
                        startPageTile(
                            title: bookmark.title,
                            host: bookmark.url.host ?? "",
                            icon: "bookmark.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var recentGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Visited")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(recentHistory) { entry in
                    Button {
                        appState.openInSelectedTab(entry.url)
                    } label: {
                        startPageTile(
                            title: entry.title,
                            host: entry.url.host ?? "",
                            icon: "clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func startPageTile(title: String, host: String, icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Text(host)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
