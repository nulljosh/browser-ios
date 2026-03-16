import SwiftUI

struct TabSwitcherView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(appState.tabs) { tab in
                        tabCard(for: tab)
                    }
                }
                .padding()
            }
            .navigationTitle("Tabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appState.addTab()
                        dismiss()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func tabCard(for tab: Tab) -> some View {
        let isSelected = appState.selectedTabID == tab.id

        return VStack(spacing: 0) {
            // Tab preview area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(height: 140)
                    .overlay {
                        VStack(spacing: 8) {
                            if let favicon = tab.favicon {
                                Image(uiImage: favicon)
                                    .resizable()
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "globe")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }

                            Text(tab.url.host ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                Button {
                    appState.closeTab(id: tab.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(6)
            }

            // Title
            Text(tab.title)
                .font(.caption)
                .lineLimit(1)
                .padding(.top, 6)
                .padding(.horizontal, 4)

            if tab.isPrivate {
                Text("Private")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectTab(id: tab.id)
            dismiss()
        }
    }
}
