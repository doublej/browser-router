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

    private let chromiumProfilePaths: [String: String] = [
        "com.google.Chrome": "Google/Chrome",
        "com.microsoft.edgemac": "Microsoft Edge",
        "com.brave.Browser": "BraveSoftware/Brave-Browser",
        "com.vivaldi.Vivaldi": "Vivaldi",
        "com.operasoftware.Opera": "com.operasoftware.Opera"
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

            let profiles = detectProfiles(for: bundleID)
            detected.append(Browser(id: bundleID, name: name, path: appURL, profiles: profiles))
        }

        return detected.sorted { lhs, rhs in
            let lhsKnown = knownBrowserIDs.contains(lhs.id)
            let rhsKnown = knownBrowserIDs.contains(rhs.id)
            if lhsKnown != rhsKnown { return lhsKnown }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func detectProfiles(for bundleID: String) -> [BrowserProfile] {
        if bundleID == "org.mozilla.firefox" {
            return detectFirefoxProfiles()
        }

        guard let relativePath = chromiumProfilePaths[bundleID] else { return [] }
        return detectChromiumProfiles(relativePath: relativePath)
    }

    private func detectChromiumProfiles(relativePath: String) -> [BrowserProfile] {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard let baseDir = appSupport?.appendingPathComponent(relativePath) else { return [] }

        let localStateURL = baseDir.appendingPathComponent("Local State")
        guard let data = FileManager.default.contents(atPath: localStateURL.path),
              let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let profileInfo = json["profile"] as? [String: Any],
              let infoCache = profileInfo["info_cache"] as? [String: Any] else {
            return []
        }

        var profiles: [BrowserProfile] = []
        for (dirName, info) in infoCache {
            guard let infoDict = info as? [String: Any],
                  let name = infoDict["name"] as? String else { continue }

            let id = "\(relativePath)/\(dirName)"
            profiles.append(BrowserProfile(id: id, name: name, directoryName: dirName))
        }

        return profiles.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func detectFirefoxProfiles() -> [BrowserProfile] {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        guard appSupport != nil else { return [] }

        let iniPath = appSupport?.appendingPathComponent("Firefox/profiles.ini")
        guard let iniPath = iniPath,
              let content = FileManager.default.contents(atPath: iniPath.path),
              let iniString = String(data: content, encoding: .utf8) else {
            return []
        }

        var profiles: [BrowserProfile] = []
        var currentName: String?
        var currentPath: String?

        for line in iniString.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("[Profile") {
                if let name = currentName, let path = currentPath {
                    let dirName = URL(fileURLWithPath: path).lastPathComponent
                    profiles.append(BrowserProfile(id: "firefox/\(dirName)", name: name, directoryName: dirName))
                }
                currentName = nil
                currentPath = nil
            } else if trimmed.hasPrefix("Name=") {
                currentName = String(trimmed.dropFirst(5))
            } else if trimmed.hasPrefix("Path=") {
                currentPath = String(trimmed.dropFirst(5))
            }
        }

        if let name = currentName, let path = currentPath {
            let dirName = URL(fileURLWithPath: path).lastPathComponent
            profiles.append(BrowserProfile(id: "firefox/\(dirName)", name: name, directoryName: dirName))
        }

        return profiles
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

    func profile(browserID: String, profileID: String) -> BrowserProfile? {
        browser(for: browserID)?.profiles.first { $0.id == profileID }
    }
}
