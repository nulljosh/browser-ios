import SwiftUI

@main
struct BrowserApp: App {
    @UIApplicationDelegateAdaptor(BrowserAppDelegate.self) var appDelegate
    @State private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            BrowserView()
                .environment(appState)
        }
    }
}

final class BrowserAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Storage.clearCleanShutdownFlag()

        if !Storage.wasCleanShutdown(), let recovery = Storage.loadCrashRecoveryState() {
            let timeSinceCrash = Date().timeIntervalSince(recovery.timestamp)
            if timeSinceCrash < 3600 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.offerCrashRecovery(recovery)
                }
            }
        }
        Storage.clearCrashRecoveryState()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        Task { @MainActor in
            AppState.shared.handleCleanShutdown()
        }
    }

    private func offerCrashRecovery(_ recovery: CrashRecoveryData) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }

        let alert = UIAlertController(
            title: "Restore Previous Session?",
            message: "Browser quit unexpectedly. Would you like to restore your \(recovery.tabs.count) open tab(s)?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Restore", style: .default) { _ in
            Task { @MainActor in
                let state = AppState.shared
                for tabData in recovery.tabs {
                    if let url = URL(string: tabData.urlString) {
                        state.addTab(url: url)
                    }
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Start Fresh", style: .cancel))
        rootVC.present(alert, animated: true)
    }
}
