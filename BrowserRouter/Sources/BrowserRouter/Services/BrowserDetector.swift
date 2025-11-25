import AppKit
import CoreServices

final class BrowserDetector: ObservableObject {
    @Published private(set) var browsers: [Browser] = []
    @Published private(set) var defaultBrowserID: String?

    private let knownBrowserIDs: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "com.brave.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
        "company.thebrowser.Browser"
    ]

    init() {
        refresh()
    }

    func refresh() {
        browsers = detectBrowsers()
        defaultBrowserID = getDefaultBrowserID()
    }

    private func detectBrowsers() -> [Browser] {
        guard let testURL = URL(string: "https://example.com") else { return [] }

        guard let appURLs = LSCopyApplicationURLsForURL(testURL as CFURL, .all)?.takeRetainedValue() as? [URL] else {
            return []
        }

        var detected: [Browser] = []
        var seenIDs: Set<String> = []

        let selfBundleID = Bundle.main.bundleIdentifier ?? "com.browserrouter.app"

        for appURL in appURLs {
            guard let bundle = Bundle(url: appURL),
                  let bundleID = bundle.bundleIdentifier,
                  bundleID != selfBundleID,
                  !seenIDs.contains(bundleID) else { continue }

            seenIDs.insert(bundleID)

            let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? appURL.deletingPathExtension().lastPathComponent

            detected.append(Browser(id: bundleID, name: name, path: appURL))
        }

        return detected.sorted { lhs, rhs in
            let lhsKnown = knownBrowserIDs.contains(lhs.id)
            let rhsKnown = knownBrowserIDs.contains(rhs.id)
            if lhsKnown != rhsKnown { return lhsKnown }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func getDefaultBrowserID() -> String? {
        guard let testURL = URL(string: "https://example.com"),
              let appURL = NSWorkspace.shared.urlForApplication(toOpen: testURL),
              let bundle = Bundle(url: appURL) else {
            return nil
        }
        return bundle.bundleIdentifier
    }

    func browser(for id: String) -> Browser? {
        browsers.first { $0.id == id }
    }
}
