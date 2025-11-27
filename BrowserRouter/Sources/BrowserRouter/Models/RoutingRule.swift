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

struct PortRange: Codable, Hashable {
    var start: Int
    var end: Int

    init(_ single: Int) {
        self.start = single
        self.end = single
    }

    init(start: Int, end: Int) {
        self.start = min(start, end)
        self.end = max(start, end)
    }

    func contains(_ port: Int) -> Bool {
        port >= start && port <= end
    }

    var displayString: String {
        start == end ? "\(start)" : "\(start)-\(end)"
    }

    static func parse(_ string: String) -> PortRange? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        if let single = Int(trimmed), single > 0, single <= 65535 {
            return PortRange(single)
        }

        let parts = trimmed.split(separator: "-")
        guard parts.count == 2,
              let start = Int(parts[0]),
              let end = Int(parts[1]),
              start > 0, end <= 65535 else { return nil }

        return PortRange(start: start, end: end)
    }
}

struct RoutingRule: Identifiable, Codable, Hashable {
    let id: UUID
    var pattern: String
    var matchType: MatchType
    var browserID: String
    var profileID: String?
    var portRange: PortRange?
    var enabled: Bool
    var priority: Int

    init(
        id: UUID = UUID(),
        pattern: String,
        matchType: MatchType,
        browserID: String,
        profileID: String? = nil,
        portRange: PortRange? = nil,
        enabled: Bool = true,
        priority: Int = 0
    ) {
        self.id = id
        self.pattern = pattern
        self.matchType = matchType
        self.browserID = browserID
        self.profileID = profileID
        self.portRange = portRange
        self.enabled = enabled
        self.priority = priority
    }
}
