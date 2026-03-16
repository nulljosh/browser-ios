# Browser iOS

Native iOS web browser using WebKit (`WKWebView`). No Chromium. v2.0.0.

## Architecture

- SwiftUI app targeting iOS 17+
- WKWebView for rendering
- xcodegen for project file generation
- @Observable for state management (AppState singleton)
- JSON persistence in Application Support/Browser/
- Persistent WKWebsiteDataStore (shared across tabs, ephemeral for private mode)
- Bundled WebKit content blocker rules (easylist.json)
- Crash recovery via periodic state snapshots (30s interval)

## Project Structure

```text
browser-ios/
  AppState.swift       # Singleton: tabs, bookmarks, history, reader mode, private mode, autocomplete, content blocker
  BrowserApp.swift     # @main entry point, UIApplicationDelegate, crash recovery prompt
  Storage.swift        # JSON persistence, crash recovery state
  Preferences.swift    # Search engine, privacy, zoom, start page, tab suspension
  PrivacyManager.swift # Content blocker compilation, tracker counting, auto-clear
  TabManager.swift     # Tab suspension, crash recovery timer
  Extensions/
    URL+Extensions.swift # User input parsing, configurable search engines, HTTPS upgrade
  Models/
    Tab.swift          # Pinned, audio, muted, zoom, suspended, private
    Bookmark.swift     # Folders, Codable
    HistoryEntry.swift # Codable
  Views/
    BrowserView.swift      # Main layout, find bar, bottom toolbar, sheet presentations
    WebViewWrapper.swift   # UIViewRepresentable, WKNavigationDelegate, WKUIDelegate, HTTPS upgrade, favicon
    AddressBarView.swift   # Autocomplete, lock icon, tracker badge
    TabSwitcherView.swift  # Tab grid with close buttons
    BookmarksView.swift    # Folder-grouped list, swipe-to-delete
    HistoryView.swift      # Searchable history list
    SettingsView.swift     # Search engine, privacy, display settings
    ReaderView.swift       # Font/size/background controls, JS article extraction
    StartPageView.swift    # Bookmarks grid, recent history
  easylist.json        # Bundled content blocker rules
  Assets.xcassets/     # AppIcon placeholder
  Info.plist
  project.yml          # xcodegen config
```

## Build

```sh
xcodegen generate
xcodebuild -scheme BrowseriOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Features

Tabs (switcher, pinning, suspension, private mode), content blocker (easylist), reader mode, configurable search engine, HTTPS-only mode, preferences, crash recovery, autocomplete, address bar (lock icon, tracker badge), bookmark folders, history search, start page, settings, find in page, error pages with retry, persistence, favicon fetching.
