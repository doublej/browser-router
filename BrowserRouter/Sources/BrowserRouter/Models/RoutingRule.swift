import Foundation

enum MatchType: String, Codable, CaseIterable {
    case contains
    case domain
    case wildcard
    case regex

    var displayName: String {
        switch self {
        case .contains: "Contains"
        case .domain: "Domain"
        case .wildcard: "Wildcard"
        case .regex: "Regex"
        }
    }

    var placeholder: String {
        switch self {
        case .contains: "github"
        case .domain: "github.com"
        case .wildcard: "*.github.com/*"
        case .regex: ".*\\.google\\.com/.*"
        }
    }

    var description: String {
        switch self {
        case .contains:
            "Match if URL contains this text anywhere"
        case .domain:
            "Match by domain name only (ignores protocol and path)"
        case .wildcard:
            "Match full URL with wildcards (* = any, ? = single char)"
        case .regex:
            "Match full URL with regular expression"
        }
    }
}

struct RoutingRule: Identifiable, Codable, Hashable {
    let id: UUID
    var pattern: String
    var matchType: MatchType
    var browserID: String
    var enabled: Bool
    var priority: Int

    init(
        id: UUID = UUID(),
        pattern: String,
        matchType: MatchType,
        browserID: String,
        enabled: Bool = true,
        priority: Int = 0
    ) {
        self.id = id
        self.pattern = pattern
        self.matchType = matchType
        self.browserID = browserID
        self.enabled = enabled
        self.priority = priority
    }
}
