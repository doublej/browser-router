import AppKit

struct BrowserProfile: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let directoryName: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BrowserProfile, rhs: BrowserProfile) -> Bool {
        lhs.id == rhs.id
    }
}

struct Browser: Identifiable, Hashable {
    let id: String  // Bundle identifier
    let name: String
    let path: URL
    var profiles: [BrowserProfile]

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: path.path)
    }

    var supportsProfiles: Bool {
        !profiles.isEmpty
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Browser, rhs: Browser) -> Bool {
        lhs.id == rhs.id
    }
}

extension Browser: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, path, profiles
    }
}
