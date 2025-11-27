# Browser Router

<p align="center">
  <img src="BrowserRouter/Resources/AppIcon.svg" width="128" height="128" alt="Browser Router Icon">
</p>

A macOS menu bar app that acts as your default browser and intelligently routes URLs to the right browser (and even the right profile) based on customizable rules.

**The problem:** With so many new browsers featuring AI capabilities (Atlas, Dia, Comet, etc.), it's annoying when you're debugging and your AI-powered browser is set as default - every link opens there.

**The solution:** Set Browser Router as your default browser. It intercepts all URL clicks and routes them based on rules you define:
- Send `localhost:*` to Chrome with your DevTools profile
- Route `github.com` to your work browser
- Open `*.slack.com` in a specific browser/profile
- Everything else goes to your favorite AI browser

**Visual feedback:** When a URL is redirected, the menu bar icon briefly shows the destination browser's icon - so you always know where it went.

## Download

**[Download Browser Router v1.0.0](https://github.com/doublej/browser-router/releases/latest/download/Browser-Router-v1.0.0.zip)** (macOS 13+)

Or see all releases on the [Releases page](https://github.com/doublej/browser-router/releases).

## Features

- **Rule-based routing** — Send URLs to specific browsers based on domain, pattern, wildcard, or regex
- **Profile support** — Route to specific browser profiles (Chrome, Firefox, Edge, Brave, Vivaldi)
- **Priority ordering** — First matching rule wins
- **Notifications** — Optional banner, sound, and menu bar icon flash on routing
- **Recent history** — Track recently routed URLs in the menu bar

### Setup

1. Launch Browser Router from Applications
2. Click the menu bar icon → "Set as Default Browser"
3. Confirm in the system dialog
4. Add routing rules in Preferences (⌘,)

## Usage

### Creating Rules

| Match Type | Example | Matches |
|------------|---------|---------|
| Domain | `github.com` | Exact domain match |
| Contains | `docs` | URL contains string |
| Wildcard | `*.google.*` | Glob-style pattern |
| Regex | `jira\|confluence` | Regular expression |

Rules are evaluated in priority order. First match wins. URLs without a matching rule go to your system default browser.

### Browser Profiles

For Chromium-based browsers and Firefox, you can route to specific profiles. Browser Router auto-detects available profiles.

## Tech Stack

- Swift 6.2 / SwiftPM (no Xcode project)
- SwiftUI + AppKit hybrid
- macOS 26 Liquid Glass UI
