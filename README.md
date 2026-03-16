![Browser](icon.svg)

# Browser for iOS

![version](https://img.shields.io/badge/version-v2.0.0-blue)

A native iOS web browser built on WebKit. No Chromium.

## Stack

- WebKit (`WKWebView`)
- SwiftUI
- iOS 17+
- `xcodegen`

## Features

- Native iOS browser UI built directly on WebKit
- Tab management with switcher, pinning, suspension, private browsing
- Content blocker with bundled easylist rules (~100 ad/tracker domains)
- Reader mode with font, size, and background controls
- Configurable search engine (DuckDuckGo, Google, Bing, Ecosia)
- HTTPS-only mode with automatic upgrade
- Preferences system (search engine, homepage, content blocker, HTTPS-only, auto-clear, zoom, tab suspension)
- Crash recovery (state saved every 30s, restore prompt on next launch)
- Autocomplete from bookmarks and history
- Address bar with lock icon and tracker count badge
- Bookmark folders with list view and swipe-to-delete
- History search
- Start page with bookmarks grid and recent history
- Settings sheet
- Find in page
- Built-in error pages with retry
- Persistence for tabs, bookmarks, history, and preferences
- Favicon fetching

## Build

```bash
xcodegen generate
xcodebuild -scheme BrowseriOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture

21 Swift source files.

- **Models**: `Tab`, `Bookmark`, `HistoryEntry`
- **App**: `AppState` (@Observable singleton), `BrowserApp` (entry point + UIApplicationDelegate), `Storage` (JSON persistence + crash recovery), `Preferences` (search engine, privacy, zoom), `PrivacyManager` (content blocker compilation, tracker counting), `TabManager` (suspension, crash recovery timer)
- **Views**: `BrowserView` (main layout), `WebViewWrapper` (UIViewRepresentable, WKNavigationDelegate, WKUIDelegate, persistent data store, HTTPS upgrade), `AddressBarView`, `TabSwitcherView`, `BookmarksView`, `HistoryView`, `SettingsView`, `ReaderView`, `StartPageView`
- **Extensions**: `URL+Extensions` (user input parsing, configurable search engines, HTTPS upgrade)
- **Resources**: `easylist.json`, `Assets.xcassets`

## License

MIT 2026, Joshua Trommel
