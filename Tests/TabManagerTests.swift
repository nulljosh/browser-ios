import XCTest
@testable import BrowseriOS

@MainActor
final class TabManagerTests: XCTestCase {
    private var manager: TabManager { TabManager.shared }

    // MARK: - Mark Accessed

    func testMarkAccessedStoresDate() {
        let tabID = UUID()
        XCTAssertNil(manager.lastAccess(for: tabID))

        manager.markAccessed(tabID: tabID)
        XCTAssertNotNil(manager.lastAccess(for: tabID))
    }

    func testMarkAccessedUpdatesDate() {
        let tabID = UUID()
        manager.markAccessed(tabID: tabID)
        let first = manager.lastAccess(for: tabID)!

        Thread.sleep(forTimeInterval: 0.01)
        manager.markAccessed(tabID: tabID)
        let second = manager.lastAccess(for: tabID)!

        XCTAssertGreaterThanOrEqual(second, first)
    }

    // MARK: - Scroll Position

    func testSaveAndRetrieveScrollPosition() {
        let tabID = UUID()
        XCTAssertEqual(manager.scrollPosition(for: tabID), 0)

        manager.saveScrollPosition(350.5, for: tabID)
        XCTAssertEqual(manager.scrollPosition(for: tabID), 350.5)
    }

    // MARK: - Remove Tab

    func testRemoveTabClearsAllData() {
        let tabID = UUID()
        manager.markAccessed(tabID: tabID)
        manager.saveScrollPosition(200, for: tabID)

        manager.removeTab(tabID: tabID)

        XCTAssertNil(manager.lastAccess(for: tabID))
        XCTAssertEqual(manager.scrollPosition(for: tabID), 0)
    }

    func testRemoveNonexistentTabDoesNotCrash() {
        let tabID = UUID()
        manager.removeTab(tabID: tabID)
    }

    // MARK: - Multiple Tabs

    func testMultipleTabsTrackedIndependently() {
        let tab1 = UUID()
        let tab2 = UUID()

        manager.markAccessed(tabID: tab1)
        manager.saveScrollPosition(100, for: tab1)
        manager.markAccessed(tabID: tab2)
        manager.saveScrollPosition(200, for: tab2)

        XCTAssertEqual(manager.scrollPosition(for: tab1), 100)
        XCTAssertEqual(manager.scrollPosition(for: tab2), 200)

        manager.removeTab(tabID: tab1)
        XCTAssertNil(manager.lastAccess(for: tab1))
        XCTAssertNotNil(manager.lastAccess(for: tab2))

        manager.removeTab(tabID: tab2)
    }
}
