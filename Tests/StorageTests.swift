import XCTest
@testable import BrowseriOS

final class StorageTests: XCTestCase {

    // MARK: - Save/Load Round-Trip

    func testSaveAndLoadRoundTrip() {
        let tabs = [
            TabData(id: UUID(), urlString: "https://example.com", title: "Example", isPinned: true, scrollPosition: 150, zoomLevel: 1.25),
            TabData(id: UUID(), urlString: "https://test.com", title: "Test", isPrivate: true)
        ]
        let bookmarks = [
            Bookmark(url: URL(string: "https://apple.com")!, title: "Apple", folder: "Tech")
        ]
        let history = [
            HistoryEntry(url: URL(string: "https://visited.com")!, title: "Visited")
        ]
        let prefs = Preferences(searchEngine: .google, homepage: "https://google.com", defaultZoom: 1.5)

        Storage.save(tabs: tabs, bookmarks: bookmarks, history: history, preferences: prefs)

        let loaded = Storage.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded!.tabs.count, 2)
        XCTAssertEqual(loaded!.tabs[0].urlString, "https://example.com")
        XCTAssertEqual(loaded!.tabs[0].isPinned, true)
        XCTAssertEqual(loaded!.tabs[0].scrollPosition, 150)
        XCTAssertEqual(loaded!.tabs[0].zoomLevel, 1.25)
        XCTAssertEqual(loaded!.tabs[1].isPrivate, true)
        XCTAssertEqual(loaded!.bookmarks.count, 1)
        XCTAssertEqual(loaded!.bookmarks[0].title, "Apple")
        XCTAssertEqual(loaded!.bookmarks[0].folder, "Tech")
        XCTAssertEqual(loaded!.history.count, 1)
        XCTAssertNotNil(loaded!.preferences)
        XCTAssertEqual(loaded!.preferences!.searchEngine, .google)
        XCTAssertEqual(loaded!.preferences!.defaultZoom, 1.5)
    }

    func testHistoryCappedAt500() {
        let history = (0..<600).map { i in
            HistoryEntry(url: URL(string: "https://example.com/\(i)")!, title: "Page \(i)")
        }
        Storage.save(tabs: [], bookmarks: [], history: history)
        let loaded = Storage.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded!.history.count, 500)
    }

    // MARK: - Crash Recovery

    func testCrashRecoverySaveAndLoad() {
        let tabID = UUID()
        let tabs = [TabData(id: tabID, urlString: "https://crash.test", title: "Crash Test")]

        Storage.saveCrashRecoveryState(tabs: tabs, selectedTabID: tabID)
        let recovered = Storage.loadCrashRecoveryState()

        XCTAssertNotNil(recovered)
        XCTAssertEqual(recovered!.tabs.count, 1)
        XCTAssertEqual(recovered!.tabs[0].urlString, "https://crash.test")
        XCTAssertEqual(recovered!.selectedTabID, tabID)
    }

    func testClearCrashRecoveryState() {
        let tabs = [TabData(id: UUID(), urlString: "https://test.com", title: "Test")]
        Storage.saveCrashRecoveryState(tabs: tabs, selectedTabID: nil)
        Storage.clearCrashRecoveryState()
        let recovered = Storage.loadCrashRecoveryState()
        XCTAssertNil(recovered)
    }

    // MARK: - Clean Shutdown

    func testCleanShutdownFlag() {
        Storage.clearCleanShutdownFlag()
        XCTAssertFalse(Storage.wasCleanShutdown())

        Storage.markCleanShutdown()
        XCTAssertTrue(Storage.wasCleanShutdown())

        Storage.clearCleanShutdownFlag()
        XCTAssertFalse(Storage.wasCleanShutdown())
    }

    // MARK: - Preferences

    func testPreferencesSaveAndLoad() {
        var prefs = Preferences()
        prefs.searchEngine = .ecosia
        prefs.httpsOnlyMode = true
        prefs.tabSuspensionMinutes = 10

        Storage.savePreferences(prefs)
        let loaded = Storage.loadPreferences()

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded!.searchEngine, .ecosia)
        XCTAssertEqual(loaded!.httpsOnlyMode, true)
        XCTAssertEqual(loaded!.tabSuspensionMinutes, 10)
    }

    // MARK: - TabData Codable

    func testTabDataDefaultValues() {
        let tab = TabData(id: UUID(), urlString: "https://test.com", title: "Test")
        XCTAssertFalse(tab.isPinned)
        XCTAssertEqual(tab.scrollPosition, 0)
        XCTAssertEqual(tab.zoomLevel, 1.0)
        XCTAssertFalse(tab.isPrivate)
    }

    func testTabDataCodableRoundTrip() throws {
        let original = TabData(id: UUID(), urlString: "https://example.com", title: "Example", isPinned: true, scrollPosition: 42.5, zoomLevel: 1.75, isPrivate: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TabData.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.urlString, original.urlString)
        XCTAssertEqual(decoded.isPinned, original.isPinned)
        XCTAssertEqual(decoded.scrollPosition, original.scrollPosition)
        XCTAssertEqual(decoded.zoomLevel, original.zoomLevel)
        XCTAssertEqual(decoded.isPrivate, original.isPrivate)
    }
}
