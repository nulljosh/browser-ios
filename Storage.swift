import Foundation

struct BrowserData: Codable {
    let tabs: [TabData]
    let bookmarks: [Bookmark]
    let history: [HistoryEntry]
    let preferences: Preferences?
}

struct TabData: Codable, Sendable {
    let id: UUID
    let urlString: String
    let title: String
    let isPinned: Bool
    let scrollPosition: Double
    let zoomLevel: Double
    let isPrivate: Bool

    init(
        id: UUID,
        urlString: String,
        title: String,
        isPinned: Bool = false,
        scrollPosition: Double = 0,
        zoomLevel: Double = 1.0,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.urlString = urlString
        self.title = title
        self.isPinned = isPinned
        self.scrollPosition = scrollPosition
        self.zoomLevel = zoomLevel
        self.isPrivate = isPrivate
    }
}

struct CrashRecoveryData: Codable {
    let tabs: [TabData]
    let selectedTabID: UUID?
    let timestamp: Date
}

struct Storage {
    private static let fileManager = FileManager.default
    private static var directoryURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Browser", isDirectory: true)
    }
    private static var fileURL: URL { directoryURL.appendingPathComponent("browser_data.json") }
    private static var preferencesURL: URL { directoryURL.appendingPathComponent("preferences.json") }
    private static var crashRecoveryURL: URL { directoryURL.appendingPathComponent("crash_recovery.json") }
    private static var cleanShutdownURL: URL { directoryURL.appendingPathComponent(".clean_shutdown") }

    static func save(
        tabs: [TabData],
        bookmarks: [Bookmark],
        history: [HistoryEntry],
        preferences: Preferences? = nil
    ) {
        let cappedHistory = Array(history.prefix(500))
        let browserData = BrowserData(
            tabs: tabs,
            bookmarks: bookmarks,
            history: cappedHistory,
            preferences: preferences
        )

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(browserData)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            return
        }
    }

    static func load() -> BrowserData? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(BrowserData.self, from: data)
        } catch {
            return nil
        }
    }

    static func savePreferences(_ preferences: Preferences) {
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]
            let data = try encoder.encode(preferences)
            try data.write(to: preferencesURL, options: .atomic)
        } catch {
            return
        }
    }

    static func loadPreferences() -> Preferences? {
        do {
            let data = try Data(contentsOf: preferencesURL)
            return try JSONDecoder().decode(Preferences.self, from: data)
        } catch {
            return nil
        }
    }

    static func saveCrashRecoveryState(tabs: [TabData], selectedTabID: UUID?) {
        let recovery = CrashRecoveryData(tabs: tabs, selectedTabID: selectedTabID, timestamp: Date())
        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(recovery)
            try data.write(to: crashRecoveryURL, options: .atomic)
        } catch {
            return
        }
    }

    static func loadCrashRecoveryState() -> CrashRecoveryData? {
        do {
            let data = try Data(contentsOf: crashRecoveryURL)
            return try JSONDecoder().decode(CrashRecoveryData.self, from: data)
        } catch {
            return nil
        }
    }

    static func clearCrashRecoveryState() {
        try? fileManager.removeItem(at: crashRecoveryURL)
    }

    static func markCleanShutdown() {
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? Data().write(to: cleanShutdownURL)
    }

    static func wasCleanShutdown() -> Bool {
        fileManager.fileExists(atPath: cleanShutdownURL.path)
    }

    static func clearCleanShutdownFlag() {
        try? fileManager.removeItem(at: cleanShutdownURL)
    }
}
