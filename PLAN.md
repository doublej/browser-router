# Browser Router - Implementation Plan

## Overview
A macOS menu bar app that intercepts HTTP/HTTPS URLs and routes them to different browsers based on configurable rules.

## Architecture

### Project Structure
```
BrowserRouter/
├── Package.swift
├── Sources/
│   └── BrowserRouter/
│       ├── App/
│       │   ├── BrowserRouterApp.swift      # Main app entry, menu bar setup
│       │   └── AppDelegate.swift           # URL handling, registration
│       ├── Models/
│       │   ├── RoutingRule.swift           # Rule model with match types
│       │   └── Browser.swift               # Browser model
│       ├── Services/
│       │   ├── BrowserDetector.swift       # Scans system for browsers
│       │   ├── URLMatcher.swift            # Pattern matching engine
│       │   └── RuleStore.swift             # Persistence layer
│       └── Views/
│           ├── MenuBarView.swift           # Status item menu
│           ├── PreferencesWindow.swift     # Main preferences
│           ├── RuleListView.swift          # Rules table with drag reorder
│           └── RuleEditorView.swift        # Add/edit rule sheet
└── Resources/
    └── Info.plist                          # URL scheme registration
```

### Technology Choices
- **Swift 5.9+** with SwiftUI for UI
- **Swift Package Manager** (no Xcode project needed for initial dev)
- **AppKit** for menu bar (NSStatusItem) + SwiftUI for views
- **UserDefaults** for rule persistence (simple, works well for this use case)

## Core Components

### 1. Browser Detection (`BrowserDetector.swift`)
```swift
struct Browser: Identifiable, Codable {
    let id: String           // Bundle identifier
    let name: String         // Display name
    let path: URL            // App path
    let icon: NSImage?       // App icon (not codable)
}
```

Detection strategy:
1. Use `LSCopyApplicationURLsForURL` with a dummy http URL to get all HTTP-capable apps
2. Filter to known browser bundle IDs + any app that can handle http
3. Cache results, refresh on preferences open

Known browser bundle IDs:
- `com.apple.Safari`
- `com.google.Chrome`
- `org.mozilla.firefox`
- `com.microsoft.edgemac`
- `com.brave.Browser`
- `com.operasoftware.Opera`
- `com.vivaldi.Vivaldi`
- `company.thebrowser.Browser` (Arc)

### 2. URL Matching (`URLMatcher.swift`)

Rule types enum:
```swift
enum MatchType: String, Codable, CaseIterable {
    case contains      // Simple substring match
    case domain        // Exact domain match (ignores path)
    case wildcard      // Glob-style: * matches anything
    case regex         // Full regex pattern
}
```

Matching logic (first match wins based on priority order):
1. **Contains**: `url.absoluteString.contains(pattern)`
2. **Domain**: Extract host, compare with/without www prefix
3. **Wildcard**: Convert to regex (`*` → `.*`, escape rest)
4. **Regex**: Direct `NSRegularExpression` match

### 3. Routing Rules (`RoutingRule.swift`)
```swift
struct RoutingRule: Identifiable, Codable {
    let id: UUID
    var pattern: String
    var matchType: MatchType
    var browserID: String    // Bundle identifier
    var enabled: Bool
    var priority: Int        // For ordering
}
```

### 4. Rule Storage (`RuleStore.swift`)
- Store as JSON in UserDefaults
- Observable object for SwiftUI binding
- Import/export functionality for backup

### 5. URL Handler (`AppDelegate.swift`)
```swift
// Register for URL events
NSAppleEventManager.shared().setEventHandler(
    self,
    andSelector: #selector(handleURL),
    forEventClass: AEEventClass(kInternetEventClass),
    andEventID: AEEventID(kAEGetURL)
)
```

Routing flow:
1. Receive URL via Apple Event
2. Iterate rules by priority
3. First match → open URL in that browser
4. No match → open in system default browser

### 6. Menu Bar (`MenuBarView.swift`)
Menu structure:
```
[Icon] Browser Router
├── Enabled ✓
├── ─────────────
├── Recent URLs →
│   ├── github.com/... → Chrome
│   └── docs.google... → Safari
├── ─────────────
├── Preferences...
├── Set as Default Browser
├── ─────────────
└── Quit
```

### 7. Preferences Window (`PreferencesWindow.swift`)

Two tabs:
1. **Rules**: Table with columns [Enabled, Pattern, Type, Browser, Actions]
   - Drag to reorder
   - Add/Edit/Delete buttons
   - Test URL field to preview which browser would open

2. **Browsers**: List of detected browsers
   - Refresh button
   - Shows which is system default

## Info.plist Requirements

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>Web URL</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>http</string>
            <string>https</string>
        </array>
    </dict>
</array>
<key>LSUIElement</key>
<true/>  <!-- Menu bar app, no dock icon -->
```

## Implementation Phases

### Phase 1: Core Infrastructure
1. Create Swift Package with proper structure
2. Implement `Browser` model and `BrowserDetector`
3. Implement `RoutingRule` model and `RuleStore`
4. Implement `URLMatcher` with all match types
5. Basic `AppDelegate` with URL handling

### Phase 2: Menu Bar App
1. Set up `NSStatusItem` with icon
2. Create menu with basic items
3. Wire up enable/disable toggle
4. Add quit functionality

### Phase 3: URL Routing
1. Implement URL event handling
2. Connect to rule matching engine
3. Implement browser opening via `NSWorkspace`
4. Handle fallback to system default

### Phase 4: Preferences UI
1. Create preferences window shell
2. Build rules list with SwiftUI Table
3. Implement drag-to-reorder
4. Build rule editor sheet
5. Add browser detection refresh

### Phase 5: Polish
1. Add "Set as Default Browser" functionality
2. Recent URLs tracking
3. Test URL preview in preferences
4. App icon and menu bar icon

## Key APIs

```swift
// Open URL in specific browser
NSWorkspace.shared.open(
    [url],
    withApplicationAt: browserPath,
    configuration: .init()
)

// Get apps that can handle URLs
LSCopyApplicationURLsForURL(url as CFURL, .all)

// Set as default browser
LSSetDefaultHandlerForURLScheme("http" as CFString, bundleID as CFString)
LSSetDefaultHandlerForURLScheme("https" as CFString, bundleID as CFString)

// Get current default browser
LSCopyDefaultHandlerForURLScheme("https" as CFString)
```

## File Count Estimate
- ~12 Swift files
- 1 Package.swift
- 1 Info.plist
- Total: ~14 files

## Questions Resolved
- ✅ Match types: All four (contains, domain, wildcard, regex)
- ✅ Priority: Manual drag-to-reorder (first match wins)
- ✅ Fallback: System default browser
- ✅ UI: Full preferences window
- ✅ Registration: Auto-register as default handler
- ✅ App name: "Browser Router"
