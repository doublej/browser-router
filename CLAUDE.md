# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build release
cd BrowserRouter && swift build -c release

# Build app bundle (increments build number automatically)
cd BrowserRouter && bash build-app.sh

# Run the built app
open BrowserRouter/.build/release/Browser\ Router.app

# Install to Applications
cp -r BrowserRouter/.build/release/Browser\ Router.app /Applications/
```

## Versioning

- **Version**: From git tags (e.g., `v1.0.0` → `1.0.0`)
- **Build number**: Tracked in `.build-number` file, auto-incremented on each build
- Commit `.build-number` after releases to keep build numbers in sync across machines

## Architecture

**Browser Router** is a macOS menu bar app that intercepts HTTP/HTTPS URLs and routes them to different browsers based on configurable rules. It runs as a pure SwiftPM package (no Xcode project).

### Key Flows

1. **URL Interception**: `AppDelegate` registers as URL handler via `NSAppleEventManager`. When Browser Router is set as default browser, all clicked URLs route through `handleURL → routeURL`.

2. **Rule Matching**: `URLMatcher.findMatchingRule` iterates rules sorted by priority (first match wins). Supports 4 match types: `contains`, `domain`, `wildcard`, `regex`.

3. **Browser Detection**: `BrowserDetector` uses `LSCopyApplicationURLsForURL` to discover installed browsers. Known browser bundle IDs are prioritized in the list.

4. **Persistence**: `RuleStore` saves rules, settings, and recent routes to `UserDefaults` as JSON.

### Core Components

| Component | Purpose |
|-----------|---------|
| `AppDelegate` | Menu bar setup, URL event handling, notification dispatch |
| `RuleStore` | Observable store for rules + settings, UserDefaults persistence |
| `BrowserDetector` | Discovers installed browsers via CoreServices |
| `URLMatcher` | Pattern matching engine (static methods) |

### SwiftUI + AppKit Hybrid

- App entry: `@main` SwiftUI app with `@NSApplicationDelegateAdaptor`
- Menu bar: `NSStatusItem` with programmatic `NSMenu`
- Preferences window: `NSWindow` hosting SwiftUI views via `NSHostingView`
- Window lifecycle managed via `NSWindowDelegate`

## Tech Stack

- Swift 6.2 / macOS 26 (Tahoe)
- SwiftPM only (no Xcode project)
- `LSUIElement: true` (menu bar app, no dock icon)

## UI Patterns

Uses macOS 26 Liquid Glass effects:

- Wrap adjacent glass items in `GlassEffectContainer` to prevent sampling conflicts
- Use `.glassEffect(.regular, in: .rect(cornerRadius: X))` - pass shape directly, never use `.clipShape()` after
- Add `.scrollClipDisabled()` to ScrollViews to prevent shadow clipping
