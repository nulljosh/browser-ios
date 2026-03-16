import SwiftUI

struct BrowserView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                if appState.selectedTab?.isLoading == true {
                    ProgressView(value: appState.loadingProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }

                // Content
                ZStack {
                    if appState.showReaderMode {
                        ReaderView()
                            .environment(appState)
                    } else if let selectedTabID = appState.selectedTabID {
                        WebViewWrapper(appState: appState, tabID: selectedTabID)
                            .id(selectedTabID)
                    } else {
                        ContentUnavailableView("No Tab", systemImage: "safari")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Find bar
                if appState.showFindBar {
                    findBar
                }

                Divider()

                // Bottom toolbar
                bottomToolbar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    addressBar
                }
            }
            .sheet(isPresented: $state.showTabSwitcher) {
                TabSwitcherView()
                    .environment(appState)
            }
            .sheet(isPresented: $state.showBookmarks) {
                BookmarksView()
                    .environment(appState)
            }
            .sheet(isPresented: $state.showHistory) {
                HistoryView()
                    .environment(appState)
            }
            .sheet(isPresented: $state.showSettings) {
                SettingsView()
                    .environment(appState)
            }
        }
    }

    // MARK: - Address Bar

    private var addressBar: some View {
        AddressBarView(appState: appState)
    }

    // MARK: - Find Bar

    private var findBar: some View {
        HStack(spacing: 8) {
            TextField("Find in page", text: Binding(
                get: { appState.findText },
                set: { appState.findText = $0 }
            ))
            .textFieldStyle(.roundedBorder)
            .onSubmit { appState.findInPage(text: appState.findText) }

            Button("Find") { appState.findInPage(text: appState.findText) }
                .buttonStyle(.bordered)

            Button { appState.showFindBar = false; appState.clearFind() } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            Button { appState.goBack() } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!(appState.selectedTab?.canGoBack ?? false))

            Spacer()

            Button { appState.goForward() } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!(appState.selectedTab?.canGoForward ?? false))

            Spacer()

            Button { appState.toggleBookmark() } label: {
                Image(systemName: appState.isCurrentPageBookmarked ? "star.fill" : "star")
            }

            Spacer()

            Button { appState.showTabSwitcher = true } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    Text("\(appState.tabs.count)")
                        .font(.system(size: 12, weight: .semibold))
                }
            }

            Spacer()

            Menu {
                Button { appState.addTab() } label: { Label("New Tab", systemImage: "plus") }
                Button { appState.addTab(isPrivate: true) } label: { Label("Private Tab", systemImage: "eye.slash") }
                Button { appState.reopenClosedTab() } label: { Label("Reopen Tab", systemImage: "arrow.uturn.backward") }
                Divider()
                Button { appState.showBookmarks = true } label: { Label("Bookmarks", systemImage: "bookmark") }
                Button { appState.showHistory = true } label: { Label("History", systemImage: "clock") }
                Button { appState.showFindBar.toggle() } label: { Label("Find in Page", systemImage: "magnifyingglass") }
                Button { appState.toggleReaderMode() } label: { Label("Reader Mode", systemImage: "doc.plaintext") }
                Divider()
                Button { appState.showSettings = true } label: { Label("Settings", systemImage: "gearshape") }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .font(.system(size: 18))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }
}
