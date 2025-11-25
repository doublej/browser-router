import AppKit

struct Browser: Identifiable, Hashable {
    let id: String  // Bundle identifier
    let name: String
    let path: URL

    var icon: NSImage? {
        NSWorkspace.shared.icon(forFile: path.path)
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
        case id, name, path
    }
}
