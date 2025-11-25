import AppKit
import CoreServices
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var preferencesWindow: NSWindow?
    private var originalIcon: NSImage?
    private var iconResetTask: DispatchWorkItem?

    let ruleStore = RuleStore()
    let browserDetector = BrowserDetector()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Debug bundle information
        if let bundleID = Bundle.main.bundleIdentifier {
            print("✓ Bundle ID: \(bundleID)")
            print("✓ Bundle Path: \(Bundle.main.bundlePath)")
            print("✓ Bundle URL: \(Bundle.main.bundleURL)")
        } else {
            print("⚠️ WARNING: Bundle identifier is nil!")
        }
        
        setupStatusItem()
        registerURLHandler()
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        originalIcon = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "Browser Router")
        button.image = originalIcon
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let enabledItem = NSMenuItem(
            title: ruleStore.routingEnabled ? "Routing Enabled" : "Routing Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.state = ruleStore.routingEnabled ? .on : .off
        menu.addItem(enabledItem)

        menu.addItem(NSMenuItem.separator())

        if ruleStore.notificationSettings.trackRecent && !ruleStore.recentRoutes.isEmpty {
            let recentItem = NSMenuItem(title: "Recent", action: nil, keyEquivalent: "")
            let recentMenu = NSMenu()

            for route in ruleStore.recentRoutes.prefix(10) {
                let letter = browserLetter(for: route.browserName)
                let item = NSMenuItem(
                    title: "[\(letter)] \(route.displayURL) → \(route.browserName)",
                    action: nil,
                    keyEquivalent: ""
                )
                recentMenu.addItem(item)
            }

            recentMenu.addItem(NSMenuItem.separator())
            recentMenu.addItem(NSMenuItem(
                title: "Clear Recent",
                action: #selector(clearRecent),
                keyEquivalent: ""
            ))

            recentItem.submenu = recentMenu
            menu.addItem(recentItem)
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem(
            title: "Set as Default Browser",
            action: #selector(setAsDefaultBrowser),
            keyEquivalent: ""
        ))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Browser Router",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))

        return menu
    }

    private func browserLetter(for browserName: String) -> Character {
        guard let index = browserDetector.browsers.firstIndex(where: { $0.name == browserName }) else {
            return "?"
        }
        let letterIndex = index % 26
        return Character(UnicodeScalar("A".unicodeScalars.first!.value + UInt32(letterIndex))!)
    }

    private func browserLetter(for browser: Browser) -> Character {
        guard let index = browserDetector.browsers.firstIndex(where: { $0.id == browser.id }) else {
            return "?"
        }
        let letterIndex = index % 26
        return Character(UnicodeScalar("A".unicodeScalars.first!.value + UInt32(letterIndex))!)
    }

    @objc private func clearRecent() {
        ruleStore.clearRecentRoutes()
        statusItem.menu = buildMenu()
    }

    @objc private func toggleEnabled() {
        ruleStore.toggleEnabled()
        statusItem.menu = buildMenu()
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            let contentView = PreferencesView()
                .environmentObject(ruleStore)
                .environmentObject(browserDetector)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 700, height: 550),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Browser Router"
            window.center()
            window.contentView = NSHostingView(rootView: contentView)
            window.isReleasedWhenClosed = false
            window.delegate = self
            preferencesWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func setAsDefaultBrowser() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            let alert = NSAlert()
            alert.messageText = "Bundle Identifier Error"
            alert.informativeText = "Cannot determine app bundle identifier. Make sure the app is properly built and installed."
            alert.alertStyle = .critical
            alert.runModal()
            return
        }

        let infoAlert = NSAlert()
        infoAlert.messageText = "Select Browser Router"
        infoAlert.informativeText = "A system dialog will appear. Choose \"Browser Router\" to enable URL routing."
        infoAlert.addButton(withTitle: "Continue")
        infoAlert.addButton(withTitle: "Cancel")

        guard infoAlert.runModal() == .alertFirstButtonReturn else { return }

        let httpResult = LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
        let httpsResult = LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)
        
        if httpResult != noErr || httpsResult != noErr {
            let alert = NSAlert()
            alert.messageText = "Registration Error"
            alert.informativeText = "Failed to register as default browser. The app may need to be built and run from the Applications folder.\n\nError codes: HTTP=\(httpResult), HTTPS=\(httpsResult)"
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.browserDetector.refresh()
            self?.showDefaultBrowserStatus(expectedID: bundleID)
        }
    }

    private func showDefaultBrowserStatus(expectedID: String) {
        let alert = NSAlert()

        if browserDetector.defaultBrowserID == expectedID {
            alert.messageText = "Success"
            alert.informativeText = "Browser Router is now your default browser."
            alert.alertStyle = .informational
        } else {
            let currentBrowser = browserDetector.defaultBrowserID
                .flatMap { browserDetector.browser(for: $0)?.name } ?? "Unknown"
            alert.messageText = "Browser Router Not Selected"
            alert.informativeText = "Default browser is still \(currentBrowser).\n\nTry again and select \"Browser Router\" in the system dialog."
            alert.alertStyle = .warning
        }
        alert.runModal()
    }

    private func registerURLHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }

        routeURL(url)
    }

    private func routeURL(_ url: URL) {
        guard ruleStore.routingEnabled else {
            openInSystemDefault(url)
            return
        }

        if let rule = URLMatcher.findMatchingRule(url: url, rules: ruleStore.rules),
           let browser = browserDetector.browser(for: rule.browserID) {
            openURL(url, in: browser)
            notifyRouting(url: url, browser: browser)
        } else if let defaultID = browserDetector.defaultBrowserID,
                  let browser = browserDetector.browser(for: defaultID) {
            openInSystemDefault(url)
            notifyRouting(url: url, browser: browser)
        } else {
            openInSystemDefault(url)
        }
    }

    private func notifyRouting(url: URL, browser: Browser) {
        let settings = ruleStore.notificationSettings

        if settings.trackRecent {
            let route = RecentRoute(url: url.absoluteString, browserName: browser.name)
            ruleStore.addRecentRoute(route)
            DispatchQueue.main.async { self.statusItem.menu = self.buildMenu() }
        }

        if settings.showBanner {
            showNotificationBanner(url: url, browser: browser)
        }

        if settings.flashIcon {
            showBrowserIcon(browser: browser)
        }

        if settings.playSound {
            playSound(named: settings.soundName)
        }
    }

    private func showNotificationBanner(url: URL, browser: Browser) {
        let letter = browserLetter(for: browser)
        let content = UNMutableNotificationContent()
        content.title = "URL Routed [\(letter)]"
        content.body = "\(url.host ?? url.absoluteString) → \(browser.name)"
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func showBrowserIcon(browser: Browser) {
        guard let button = statusItem.button else { return }

        iconResetTask?.cancel()

        let letter = browserLetter(for: browser)
        let iconWithBadge = createBrowserIconWithBadge(browser: browser, letter: letter)
        button.image = iconWithBadge

        let resetTask = DispatchWorkItem { [weak self] in
            button.image = self?.originalIcon
        }
        iconResetTask = resetTask
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: resetTask)
    }

    private func createBrowserIconWithBadge(browser: Browser, letter: Character) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)

        image.lockFocus()

        if let browserIcon = browser.icon {
            let iconRect = NSRect(x: 0, y: 0, width: 18, height: 18)
            browserIcon.draw(in: iconRect)
        }

        let badgeRect = NSRect(x: 12, y: 0, width: 10, height: 10)
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        NSColor.systemBlue.setFill()
        badgePath.fill()

        let letterStr = String(letter)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let letterSize = letterStr.size(withAttributes: attrs)
        let letterPoint = NSPoint(
            x: badgeRect.midX - letterSize.width / 2,
            y: badgeRect.midY - letterSize.height / 2
        )
        letterStr.draw(at: letterPoint, withAttributes: attrs)

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    private func playSound(named name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }

    private func openURL(_ url: URL, in browser: Browser) {
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: browser.path,
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }
    }

    private func openInSystemDefault(_ url: URL) {
        guard let defaultID = browserDetector.defaultBrowserID,
              defaultID != Bundle.main.bundleIdentifier,
              let browser = browserDetector.browser(for: defaultID) else {
            if let safari = browserDetector.browser(for: "com.apple.Safari") {
                openURL(url, in: safari)
            }
            return
        }
        openURL(url, in: browser)
    }
}
