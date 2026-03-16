import XCTest
@testable import BrowseriOS

final class URLExtensionsTests: XCTestCase {

    // MARK: - fromUserInput

    func testFullHTTPSURL() {
        let url = URL.fromUserInput("https://example.com")
        XCTAssertEqual(url?.absoluteString, "https://example.com")
    }

    func testFullHTTPURL() {
        let url = URL.fromUserInput("http://example.com")
        XCTAssertEqual(url?.absoluteString, "http://example.com")
    }

    func testHostWithDot() {
        let url = URL.fromUserInput("example.com")
        XCTAssertEqual(url?.absoluteString, "https://example.com")
    }

    func testLocalhost() {
        let url = URL.fromUserInput("localhost")
        XCTAssertEqual(url?.absoluteString, "https://localhost")
    }

    func testLocalhostWithPort() {
        let url = URL.fromUserInput("localhost:3000")
        XCTAssertEqual(url?.absoluteString, "https://localhost:3000")
    }

    func testSearchQuery() {
        let url = URL.fromUserInput("swift programming", searchEngine: .duckDuckGo)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.hasPrefix("https://duckduckgo.com/?q="))
        XCTAssertTrue(url!.absoluteString.contains("swift"))
    }

    func testSearchQueryWithGoogleEngine() {
        let url = URL.fromUserInput("test query", searchEngine: .google)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.hasPrefix("https://www.google.com/search?q="))
    }

    func testEmptyInputReturnsNil() {
        XCTAssertNil(URL.fromUserInput(""))
        XCTAssertNil(URL.fromUserInput("   "))
    }

    func testWhitespaceIsTrimmed() {
        let url = URL.fromUserInput("  https://example.com  ")
        XCTAssertEqual(url?.absoluteString, "https://example.com")
    }

    // MARK: - httpsUpgraded

    func testHTTPUpgradesToHTTPS() {
        let http = URL(string: "http://example.com/path?q=1")!
        let upgraded = http.httpsUpgraded
        XCTAssertNotNil(upgraded)
        XCTAssertEqual(upgraded!.scheme, "https")
        XCTAssertEqual(upgraded!.host, "example.com")
        XCTAssertEqual(upgraded!.path, "/path")
    }

    func testHTTPSReturnsNil() {
        let https = URL(string: "https://example.com")!
        XCTAssertNil(https.httpsUpgraded)
    }

    func testNonHTTPReturnsNil() {
        let ftp = URL(string: "ftp://files.example.com")!
        XCTAssertNil(ftp.httpsUpgraded)
    }

    // MARK: - isHTTP / isHTTPS

    func testIsHTTP() {
        XCTAssertTrue(URL(string: "http://example.com")!.isHTTP)
        XCTAssertFalse(URL(string: "https://example.com")!.isHTTP)
        XCTAssertFalse(URL(string: "ftp://example.com")!.isHTTP)
    }

    func testIsHTTPS() {
        XCTAssertTrue(URL(string: "https://example.com")!.isHTTPS)
        XCTAssertFalse(URL(string: "http://example.com")!.isHTTPS)
    }

    // MARK: - search

    func testSearchGeneratesCorrectURL() {
        let url = URL.search(query: "hello world", engine: .bing)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.hasPrefix("https://www.bing.com/search?q="))
        XCTAssertTrue(url!.absoluteString.contains("hello"))
    }

    func testSearchPercentEncodesQuery() {
        let url = URL.search(query: "a b&c", engine: .duckDuckGo)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("a%20b"))
    }

    // MARK: - displayString

    func testDisplayStringDecodesPercent() {
        let url = URL(string: "https://example.com/path%20here")!
        XCTAssertEqual(url.displayString, "https://example.com/path here")
    }
}
