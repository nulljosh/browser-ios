import XCTest
@testable import BrowseriOS

final class PreferencesTests: XCTestCase {

    // MARK: - Defaults

    func testDefaultValues() {
        let prefs = Preferences()
        XCTAssertEqual(prefs.searchEngine, .duckDuckGo)
        XCTAssertEqual(prefs.homepage, "https://duckduckgo.com")
        XCTAssertEqual(prefs.defaultZoom, 1.0)
        XCTAssertTrue(prefs.contentBlockerEnabled)
        XCTAssertFalse(prefs.httpsOnlyMode)
        XCTAssertFalse(prefs.autoClearOnQuit)
        XCTAssertTrue(prefs.startPageEnabled)
        XCTAssertEqual(prefs.tabSuspensionMinutes, 5)
        XCTAssertTrue(prefs.siteZoomLevels.isEmpty)
    }

    // MARK: - Zoom Levels

    func testZoomLevelDefaultsToGlobalZoom() {
        let prefs = Preferences(defaultZoom: 1.25)
        XCTAssertEqual(prefs.zoomLevel(for: "example.com"), 1.25)
    }

    func testSetZoomLevelForSite() {
        var prefs = Preferences()
        prefs.setZoomLevel(1.5, for: "example.com")

        XCTAssertEqual(prefs.zoomLevel(for: "example.com"), 1.5)
        XCTAssertEqual(prefs.zoomLevel(for: "other.com"), 1.0)
        XCTAssertEqual(prefs.siteZoomLevels.count, 1)
    }

    func testSetZoomLevelToDefaultRemovesEntry() {
        var prefs = Preferences()
        prefs.setZoomLevel(1.5, for: "example.com")
        XCTAssertEqual(prefs.siteZoomLevels.count, 1)

        prefs.setZoomLevel(1.0, for: "example.com")
        XCTAssertEqual(prefs.siteZoomLevels.count, 0)
    }

    func testSetZoomLevelUpdatesExisting() {
        var prefs = Preferences()
        prefs.setZoomLevel(1.5, for: "example.com")
        prefs.setZoomLevel(2.0, for: "example.com")

        XCTAssertEqual(prefs.zoomLevel(for: "example.com"), 2.0)
        XCTAssertEqual(prefs.siteZoomLevels.count, 1)
    }

    func testZoomLevelNearDefaultRemovesEntry() {
        var prefs = Preferences()
        prefs.setZoomLevel(1.5, for: "example.com")
        prefs.setZoomLevel(1.005, for: "example.com")
        XCTAssertEqual(prefs.siteZoomLevels.count, 0)
    }

    // MARK: - Search Engine URLs

    func testSearchEngineBaseURLs() {
        XCTAssertEqual(SearchEngine.duckDuckGo.searchBaseURL, "https://duckduckgo.com/?q=")
        XCTAssertEqual(SearchEngine.google.searchBaseURL, "https://www.google.com/search?q=")
        XCTAssertEqual(SearchEngine.bing.searchBaseURL, "https://www.bing.com/search?q=")
        XCTAssertEqual(SearchEngine.ecosia.searchBaseURL, "https://www.ecosia.org/search?q=")
    }

    func testSearchEngineHomeURLs() {
        XCTAssertEqual(SearchEngine.duckDuckGo.homeURL.absoluteString, "https://duckduckgo.com")
        XCTAssertEqual(SearchEngine.google.homeURL.absoluteString, "https://www.google.com")
        XCTAssertEqual(SearchEngine.bing.homeURL.absoluteString, "https://www.bing.com")
        XCTAssertEqual(SearchEngine.ecosia.homeURL.absoluteString, "https://www.ecosia.org")
    }

    // MARK: - Homepage URL

    func testHomepageURLParsesValidURL() {
        let prefs = Preferences(homepage: "https://example.com")
        XCTAssertEqual(prefs.homepageURL.absoluteString, "https://example.com")
    }

    func testHomepageURLFallsBackToDuckDuckGo() {
        let prefs = Preferences(homepage: "")
        XCTAssertEqual(prefs.homepageURL, SearchEngine.duckDuckGo.homeURL)
    }

    // MARK: - Codable

    func testPreferencesCodableRoundTrip() throws {
        var prefs = Preferences()
        prefs.searchEngine = .ecosia
        prefs.defaultZoom = 1.75
        prefs.setZoomLevel(2.0, for: "github.com")
        prefs.httpsOnlyMode = true

        let data = try JSONEncoder().encode(prefs)
        let decoded = try JSONDecoder().decode(Preferences.self, from: data)

        XCTAssertEqual(decoded.searchEngine, .ecosia)
        XCTAssertEqual(decoded.defaultZoom, 1.75)
        XCTAssertEqual(decoded.zoomLevel(for: "github.com"), 2.0)
        XCTAssertEqual(decoded.httpsOnlyMode, true)
    }
}
