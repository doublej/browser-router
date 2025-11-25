import Foundation

struct URLMatcher {
    static func matches(url: URL, rule: RoutingRule) -> Bool {
        guard rule.enabled else { return false }

        switch rule.matchType {
        case .contains:
            return matchContains(url: url, pattern: rule.pattern)
        case .domain:
            return matchDomain(url: url, pattern: rule.pattern)
        case .wildcard:
            return matchWildcard(url: url, pattern: rule.pattern)
        case .regex:
            return matchRegex(url: url, pattern: rule.pattern)
        }
    }

    private static func matchContains(url: URL, pattern: String) -> Bool {
        url.absoluteString.localizedCaseInsensitiveContains(pattern)
    }

    private static func matchDomain(url: URL, pattern: String) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        let normalizedPattern = pattern.lowercased()
            .replacingOccurrences(of: "www.", with: "")
        let normalizedHost = host.replacingOccurrences(of: "www.", with: "")
        return normalizedHost == normalizedPattern || normalizedHost.hasSuffix("." + normalizedPattern)
    }

    private static func matchWildcard(url: URL, pattern: String) -> Bool {
        let regexPattern = wildcardToRegex(pattern)
        return matchRegex(url: url, pattern: regexPattern)
    }

    private static func matchRegex(url: URL, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        let urlString = url.absoluteString
        let range = NSRange(urlString.startIndex..., in: urlString)
        return regex.firstMatch(in: urlString, range: range) != nil
    }

    private static func wildcardToRegex(_ pattern: String) -> String {
        var result = NSRegularExpression.escapedPattern(for: pattern)
        result = result.replacingOccurrences(of: "\\*", with: ".*")
        result = result.replacingOccurrences(of: "\\?", with: ".")
        return "^" + result + "$"
    }

    static func findMatchingRule(url: URL, rules: [RoutingRule]) -> RoutingRule? {
        let sorted = rules.sorted { $0.priority < $1.priority }
        return sorted.first { matches(url: url, rule: $0) }
    }
}
