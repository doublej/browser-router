import Foundation

struct NotificationSettings: Codable, Equatable {
    var showBanner: Bool = false
    var flashIcon: Bool = true
    var trackRecent: Bool = true
    var playSound: Bool = false
    var soundName: String = "Pop"
    var maxRecentURLs: Int = 10
}

struct RecentRoute: Codable, Identifiable {
    let id: UUID
    let url: String
    let browserName: String
    let timestamp: Date

    init(url: String, browserName: String) {
        self.id = UUID()
        self.url = url
        self.browserName = browserName
        self.timestamp = Date()
    }

    var displayURL: String {
        guard let parsed = URL(string: url), let host = parsed.host else {
            return url.prefix(50) + (url.count > 50 ? "..." : "")
        }
        let path = parsed.path.prefix(20)
        return host + (path.isEmpty ? "" : String(path) + "...")
    }
}
