import Foundation
import Observation
import WebKit

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var tabs: [Tab]
    var selectedTabID: UUID?
    var bookmarks: [Bookmark]
    var history: [HistoryEntry]
    var preferences: Preferences
    var showFindBar = false
    var findText = ""
    var loadingProgress: Double = 0
    var errorMessage: String?

    var closedTabs: [TabData] = []
    var showReaderMode = false
    var readerTitle: String?
    var readerContent: String?
    var isPrivateMode = false
    var showSettings = false
    var showBookmarks = false
    var showHistory = false
    var showTabSwitcher = false
    var autocompleteResults: [AutocompleteEntry] = []
    var showAutocomplete = false

    private var webViews: [UUID: WKWebView] = [:]
    private var persistentDataStore: WKWebsiteDataStore = .default()
    private var ephemeralDataStore: WKWebsiteDataStore = .nonPersistent()

    struct AutocompleteEntry: Identifiable {
        let id = UUID()
        let title: String
        let url: URL
    }

    private init() {
        let loadedPrefs = Storage.loadPreferences() ?? Preferences()
        preferences = loadedPrefs

        if let storedData = Storage.load() {
            let restoredTabs = storedData.tabs.compactMap(Self.makeTab(from:))

            if restoredTabs.isEmpty {
                let firstTab = Self.makeDefaultTab()
                tabs = [firstTab]
                selectedTabID = firstTab.id
            } else {
                tabs = restoredTabs
                selectedTabID = restoredTabs.first?.id
            }

            bookmarks = storedData.bookmarks
            history = Array(storedData.history.prefix(500))
        } else {
            let firstTab = Self.makeDefaultTab()
            tabs = [firstTab]
            selectedTabID = firstTab.id
            bookmarks = [
                Bookmark(url: URL.homeURL, title: "DuckDuckGo", folder: "Favorites"),
                Bookmark(
                    url: URL(string: "https://developer.apple.com/documentation/webkit")!,
                    title: "WebKit Docs",
                    folder: "Development"
                )
            ]
            history = []
        }

        TabManager.shared.startCrashRecoveryTimer {
            Task { @MainActor [weak self] in
                self?.saveCrashRecoveryState()
            }
        }

        if preferences.contentBlockerEnabled {
            PrivacyManager.shared.compileContentBlockerRules()
        }
    }

    var selectedTab: Tab? {
        guard let selectedTabID else { return nil }
        return tabs.first { $0.id == selectedTabID }
    }

    var isCurrentPageBookmarked: Bool {
        guard let currentURL = selectedTab?.url else { return false }
        return bookmarks.contains { $0.url == currentURL }
    }

    func tab(for id: UUID) -> Tab? {
        tabs.first { $0.id == id }
    }

    func addTab(url: URL = .homeURL, isPrivate: Bool = false) {
        let tab = Tab(
            url: url,
            title: url.host ?? "New Tab",
            isPrivate: isPrivate || isPrivateMode
        )
        tabs.append(tab)
        selectedTabID = tab.id
        TabManager.shared.markAccessed(tabID: tab.id)
        persistState()
        load(url: url, in: tab.id)
    }

    func closeTab(id: UUID) {
        guard tabs.count > 1 else { return }
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }

        let closedTab = tabs[index]
        if !closedTab.isPrivate {
            let tabData = TabData(
                id: closedTab.id,
                urlString: closedTab.url.absoluteString,
                title: closedTab.title,
                isPinned: closedTab.isPinned,
                scrollPosition: Double(closedTab.scrollPosition),
                zoomLevel: closedTab.zoomLevel
            )
            closedTabs.append(tabData)
            if closedTabs.count > 10 { closedTabs.removeFirst() }
        }

        tabs.remove(at: index)
        webViews[id] = nil
        PrivacyManager.shared.removeTrackerCount(for: id)
        TabManager.shared.removeTab(tabID: id)

        if selectedTabID == id {
            let fallbackIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[fallbackIndex].id
        }
        persistState()
    }

    func reopenClosedTab() {
        guard let lastClosed = closedTabs.popLast() else { return }
        guard let url = URL(string: lastClosed.urlString) else { return }
        addTab(url: url)
    }

    func selectTab(id: UUID) {
        selectedTabID = id
        TabManager.shared.markAccessed(tabID: id)

        if let index = tabs.firstIndex(where: { $0.id == id }), tabs[index].isSuspended {
            tabs[index].isSuspended = false
            load(url: tabs[index].url, in: id)
        }
    }

    func webView(for tabID: UUID) -> WKWebView {
        if let existing = webViews[tabID] {
            return existing
        }

        let isPrivate = tab(for: tabID)?.isPrivate ?? false
        let config = WKWebViewConfiguration()
        config.websiteDataStore = isPrivate ? ephemeralDataStore : persistentDataStore
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = [.all]

        if preferences.contentBlockerEnabled, let ruleList = PrivacyManager.shared.compiledRuleList {
            config.userContentController.add(ruleList)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webViews[tabID] = webView
        return webView
    }

    func load(url: URL, in tabID: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        let didChangeURL = tabs[index].url != url
        if didChangeURL { tabs[index].url = url }
        if !tabs[index].isLoading { tabs[index].isLoading = true }
        if didChangeURL { persistState() }
        webView(for: tabID).load(URLRequest(url: url))
    }

    func openInSelectedTab(_ url: URL) {
        guard let selectedTabID else { return }
        load(url: url, in: selectedTabID)
    }

    func navigateCurrent(input: String) {
        guard let url = URL.fromUserInput(input, searchEngine: preferences.searchEngine) else { return }
        openInSelectedTab(url)
    }

    func goBack() {
        guard let selectedTabID, let webView = webViews[selectedTabID], webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard let selectedTabID, let webView = webViews[selectedTabID], webView.canGoForward else { return }
        webView.goForward()
    }

    func reload() {
        guard let selectedTabID, let webView = webViews[selectedTabID] else { return }
        webView.reload()
    }

    func stopLoading() {
        guard let selectedTabID, let webView = webViews[selectedTabID] else { return }
        webView.stopLoading()
    }

    func updateTabState(
        tabID: UUID,
        url: URL?,
        title: String?,
        isLoading: Bool,
        canGoBack: Bool,
        canGoForward: Bool
    ) {
        guard let index = tabs.firstIndex(where: { $0.id == tabID }) else { return }
        var shouldPersist = false
        if let url, tabs[index].url != url { tabs[index].url = url; shouldPersist = true }
        if let title, !title.isEmpty, tabs[index].title != title { tabs[index].title = title }
        if tabs[index].isLoading != isLoading { tabs[index].isLoading = isLoading }
        if tabs[index].canGoBack != canGoBack { tabs[index].canGoBack = canGoBack }
        if tabs[index].canGoForward != canGoForward { tabs[index].canGoForward = canGoForward }
        if shouldPersist { persistState() }
    }

    func addHistoryEntry(url: URL, title: String?) {
        if isPrivateMode || (selectedTab?.isPrivate ?? false) { return }
        let entry = HistoryEntry(url: url, title: title ?? url.absoluteString)
        if let latest = history.first, latest.url == entry.url,
           abs(latest.visitDate.timeIntervalSince(entry.visitDate)) < 3 { return }
        history.insert(entry, at: 0)
        if history.count > 500 { history = Array(history.prefix(500)) }
        persistState()
    }

    func toggleBookmark() {
        guard let currentTab = selectedTab else { return }
        if let index = bookmarks.firstIndex(where: { $0.url == currentTab.url }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks.append(Bookmark(url: currentTab.url, title: currentTab.title))
        }
        persistState()
    }

    func findInPage(text: String) {
        guard let selectedTabID else { return }
        let script = "window.find(\(javaScriptStringLiteral(text)), false, false, true, false, true, false);"
        webView(for: selectedTabID).evaluateJavaScript(script)
    }

    func clearFind() {
        guard let selectedTabID else { return }
        webView(for: selectedTabID).evaluateJavaScript("window.getSelection().removeAllRanges();")
    }

    func toggleReaderMode() {
        if showReaderMode {
            showReaderMode = false
            readerTitle = nil
            readerContent = nil
            return
        }

        guard let selectedTabID, let webView = webViews[selectedTabID] else { return }
        webView.evaluateJavaScript(ReaderView.extractionScript) { [weak self] result, _ in
            guard let self, let jsonString = result as? String,
                  let data = jsonString.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return }
            self.readerTitle = parsed["title"]
            self.readerContent = parsed["content"]
            self.showReaderMode = true
        }
    }

    func updateAutocomplete(query: String) {
        guard !query.isEmpty else {
            autocompleteResults = []
            showAutocomplete = false
            return
        }
        let lowered = query.lowercased()
        var results: [AutocompleteEntry] = []
        for bookmark in bookmarks where results.count < 6 {
            if bookmark.title.lowercased().contains(lowered) || bookmark.url.absoluteString.lowercased().contains(lowered) {
                results.append(AutocompleteEntry(title: bookmark.title, url: bookmark.url))
            }
        }
        for entry in history where results.count < 6 {
            if entry.title.lowercased().contains(lowered) || entry.url.absoluteString.lowercased().contains(lowered) {
                if !results.contains(where: { $0.url == entry.url }) {
                    results.append(AutocompleteEntry(title: entry.title, url: entry.url))
                }
            }
        }
        autocompleteResults = results
        showAutocomplete = !results.isEmpty
    }

    func toggleMuteTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[index].isMuted.toggle()
        if let webView = webViews[id] {
            let muted = tabs[index].isMuted
            webView.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(el => el.muted = \(muted));")
        }
    }

    // MARK: - Persistence

    func persistState() {
        let tabData = tabs.filter { !$0.isPrivate }.map {
            TabData(id: $0.id, urlString: $0.url.absoluteString, title: $0.title,
                    isPinned: $0.isPinned, scrollPosition: Double($0.scrollPosition), zoomLevel: $0.zoomLevel)
        }
        Storage.save(tabs: tabData, bookmarks: bookmarks, history: history, preferences: preferences)
    }

    func savePreferences() {
        Storage.savePreferences(preferences)
    }

    func saveCrashRecoveryState() {
        let tabData = tabs.filter { !$0.isPrivate }.map {
            TabData(id: $0.id, urlString: $0.url.absoluteString, title: $0.title,
                    isPinned: $0.isPinned, scrollPosition: Double($0.scrollPosition), zoomLevel: $0.zoomLevel)
        }
        Storage.saveCrashRecoveryState(tabs: tabData, selectedTabID: selectedTabID)
    }

    func handleCleanShutdown() {
        Storage.markCleanShutdown()
        Storage.clearCrashRecoveryState()
        TabManager.shared.stopCrashRecoveryTimer()
        if preferences.autoClearOnQuit { PrivacyManager.shared.clearBrowsingData() }
    }

    private static func makeDefaultTab() -> Tab {
        Tab(url: URL.homeURL, title: "DuckDuckGo")
    }

    private static func makeTab(from data: TabData) -> Tab? {
        guard let url = URL(string: data.urlString) else { return nil }
        return Tab(id: data.id, url: url, title: data.title, isPinned: data.isPinned,
                   scrollPosition: CGFloat(data.scrollPosition), zoomLevel: data.zoomLevel, isPrivate: data.isPrivate)
    }

    private func javaScriptStringLiteral(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let encoded = String(data: data, encoding: .utf8) else { return "\"\"" }
        return encoded
    }
}
