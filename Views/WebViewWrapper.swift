import SwiftUI
import WebKit

struct WebViewWrapper: UIViewRepresentable {
    @Bindable var appState: AppState
    let tabID: UUID

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState, tabID: tabID)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = appState.webView(for: tabID)
        context.coordinator.attach(to: webView)
        if webView.url == nil, let tab = appState.tab(for: tabID) {
            webView.load(URLRequest(url: tab.url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.attach(to: uiView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let appState: AppState
        private let tabID: UUID
        private weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?

        init(appState: AppState, tabID: UUID) {
            self.appState = appState
            self.tabID = tabID
        }

        deinit {
            progressObservation?.invalidate()
        }

        func attach(to webView: WKWebView) {
            guard self.webView !== webView else { return }
            progressObservation?.invalidate()
            self.webView = webView
            webView.navigationDelegate = self
            webView.uiDelegate = self
            observeProgress(for: webView)
            pushState(for: webView)
        }

        private func observeProgress(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.initial, .new]) { [weak self] webView, _ in
                let progress = webView.estimatedProgress
                Task { @MainActor in
                    self?.appState.loadingProgress = progress
                }
            }
        }

        private func pushState(for webView: WKWebView) {
            appState.updateTabState(
                tabID: tabID,
                url: webView.url,
                title: webView.title,
                isLoading: webView.isLoading,
                canGoBack: webView.canGoBack,
                canGoForward: webView.canGoForward
            )
        }

        private func updateFavicon(_ image: UIImage?) {
            guard let index = appState.tabs.firstIndex(where: { $0.id == tabID }) else { return }
            appState.tabs[index].favicon = image
        }

        private func fetchFavicon(for webView: WKWebView) {
            let script = """
            (() => {
                const icon = document.querySelector("link[rel~='icon'], link[rel='shortcut icon']");
                return icon?.href ?? null;
            })();
            """
            webView.evaluateJavaScript(script) { [weak self, weak webView] result, _ in
                guard let self, let webView else { return }
                let faviconURL: URL?
                if let iconString = result as? String, let iconURL = URL(string: iconString) {
                    faviconURL = iconURL
                } else if let pageURL = webView.url, let host = pageURL.host {
                    var components = URLComponents()
                    components.scheme = pageURL.scheme ?? "https"
                    components.host = host
                    components.port = pageURL.port
                    components.path = "/favicon.ico"
                    faviconURL = components.url
                } else {
                    faviconURL = nil
                }
                guard let faviconURL else { return }
                URLSession.shared.dataTask(with: URLRequest(url: faviconURL, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 15)) { data, _, _ in
                    guard let data, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async { self.updateFavicon(image) }
                }.resume()
            }
        }

        private func errorHTML(for error: Error, originalURL: URL?) -> String {
            let message = error.localizedDescription
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let retryURL = (originalURL?.absoluteString ?? "about:blank")
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "'", with: "\\'")
            return """
            <!doctype html><html><head><meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            :root{color-scheme:light dark;font-family:-apple-system,system-ui,sans-serif}
            body{margin:0;min-height:100vh;display:grid;place-items:center;padding:24px;background:#f5f5f7}
            @media(prefers-color-scheme:dark){body{background:#1c1c1e}.card{background:#2c2c2e;color:#f5f5f7}.card p{color:#a1a1a6}}
            .card{max-width:480px;padding:24px;border-radius:16px;background:#fff;box-shadow:0 8px 32px rgba(0,0,0,.1)}
            h1{margin:0 0 8px;font-size:22px} p{margin:0 0 16px;line-height:1.5;color:#666}
            button{border:0;border-radius:10px;padding:12px 20px;background:#007AFF;color:#fff;font:16px -apple-system;cursor:pointer}
            </style></head><body><main class="card"><h1>Unable to Open Page</h1><p>\(message)</p>
            <button onclick="window.location.href='\(retryURL)'">Retry</button></main></body></html>
            """
        }

        // MARK: - WKNavigationDelegate

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            pushState(for: webView)
            PrivacyManager.shared.resetTrackerCount(for: tabID)
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            pushState(for: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            pushState(for: webView)
            fetchFavicon(for: webView)
            if let url = webView.url {
                appState.addHistoryEntry(url: url, title: webView.title)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            pushState(for: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let originalURL = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL
                ?? webView.url ?? appState.tab(for: tabID)?.url
            pushState(for: webView)
            webView.loadHTMLString(errorHTML(for: error, originalURL: originalURL), baseURL: originalURL?.deletingLastPathComponent())
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                appState.addTab(url: url)
                decisionHandler(.cancel)
                return
            }
            if appState.preferences.httpsOnlyMode,
               let url = navigationAction.request.url,
               let upgraded = url.httpsUpgraded {
                decisionHandler(.cancel)
                webView.load(URLRequest(url: upgraded))
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                appState.addTab(url: url)
            }
            return nil
        }
    }
}
