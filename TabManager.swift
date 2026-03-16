import Foundation

@MainActor
final class TabManager {
    static let shared = TabManager()

    private var lastAccessDates: [UUID: Date] = [:]
    private var suspendedScrollPositions: [UUID: CGFloat] = [:]
    private var crashRecoveryTimer: Timer?

    private init() {}

    func markAccessed(tabID: UUID) {
        lastAccessDates[tabID] = Date()
    }

    func lastAccess(for tabID: UUID) -> Date? {
        lastAccessDates[tabID]
    }

    func saveScrollPosition(_ position: CGFloat, for tabID: UUID) {
        suspendedScrollPositions[tabID] = position
    }

    func scrollPosition(for tabID: UUID) -> CGFloat {
        suspendedScrollPositions[tabID] ?? 0
    }

    func removeTab(tabID: UUID) {
        lastAccessDates.removeValue(forKey: tabID)
        suspendedScrollPositions.removeValue(forKey: tabID)
    }

    func startCrashRecoveryTimer(saveHandler: @escaping @Sendable () -> Void) {
        crashRecoveryTimer?.invalidate()
        crashRecoveryTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                saveHandler()
            }
        }
    }

    func stopCrashRecoveryTimer() {
        crashRecoveryTimer?.invalidate()
        crashRecoveryTimer = nil
    }
}
