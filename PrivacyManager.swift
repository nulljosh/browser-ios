import Foundation
import WebKit

@MainActor
final class PrivacyManager {
    static let shared = PrivacyManager()

    private(set) var compiledRuleList: WKContentRuleList?
    private(set) var trackerCounts: [UUID: Int] = [:]

    private init() {}

    func compileContentBlockerRules() {
        guard let rulesURL = Bundle.main.url(forResource: "easylist", withExtension: "json"),
              let rulesData = try? Data(contentsOf: rulesURL),
              let rulesString = String(data: rulesData, encoding: .utf8) else {
            return
        }

        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "BrowserContentBlocker",
            encodedContentRuleList: rulesString
        ) { [weak self] ruleList, _ in
            if let ruleList {
                self?.compiledRuleList = ruleList
            }
        }
    }

    func incrementTrackerCount(for tabID: UUID) {
        trackerCounts[tabID, default: 0] += 1
    }

    func resetTrackerCount(for tabID: UUID) {
        trackerCounts[tabID] = 0
    }

    func removeTrackerCount(for tabID: UUID) {
        trackerCounts.removeValue(forKey: tabID)
    }

    func trackerCount(for tabID: UUID) -> Int {
        trackerCounts[tabID] ?? 0
    }

    func clearBrowsingData() {
        let dataTypes: Set<String> = [
            WKWebsiteDataTypeCookies,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeWebSQLDatabases
        ]
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: .distantPast) {}
    }
}
