import Foundation

extension URL {
    static let defaultSearchBase = "https://duckduckgo.com/?q="
    static let homeURL = URL(string: "https://duckduckgo.com")!

    static func fromUserInput(_ input: String, searchEngine: SearchEngine = .duckDuckGo) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) {
            return url
        }

        let looksLikeHost = trimmed.contains(".") || trimmed == "localhost" || trimmed.contains(":")

        if looksLikeHost, let url = URL(string: "https://\(trimmed)") {
            return url
        }

        return search(query: trimmed, engine: searchEngine)
    }

    static func search(query: String, engine: SearchEngine) -> URL? {
        let allowed = CharacterSet.urlQueryAllowed
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: engine.searchBaseURL + encoded)
    }

    var displayString: String {
        absoluteString.removingPercentEncoding ?? absoluteString
    }

    var isHTTP: Bool {
        scheme?.lowercased() == "http"
    }

    var isHTTPS: Bool {
        scheme?.lowercased() == "https"
    }

    var httpsUpgraded: URL? {
        guard isHTTP else { return nil }
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        return components?.url
    }
}
