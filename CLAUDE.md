# Browser iOS

## Rules

- WebKit only, no Chromium
- iOS 17+, SwiftUI, @Observable (not ObservableObject)
- JSON persistence in Application Support/Browser/
- Persistent WKWebsiteDataStore shared across tabs, ephemeral for private mode

## Run

```sh
xcodegen generate
xcodebuild -scheme BrowseriOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```
