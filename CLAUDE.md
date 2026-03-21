# Browser for iOS

v2.0.0

## Rules

- WebKit only, no Chromium
- iOS 17+, SwiftUI, @Observable (not ObservableObject)
- JSON persistence in Application Support/Browser/
- Persistent WKWebsiteDataStore shared across tabs, ephemeral for private mode
- No emojis

## Run

```bash
xcodegen generate
xcodebuild -scheme BrowseriOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Key Files

- BrowserApp.swift: App entry point and scene setup
- AppState.swift: Global state container for tabs and settings
- TabManager.swift: Tab lifecycle, pinning, and suspension logic
- PrivacyManager.swift: HTTPS-only mode and privacy controls
- Storage.swift: JSON persistence for app data
