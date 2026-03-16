import UIKit

struct Tab: Identifiable {
    let id: UUID
    var url: URL
    var title: String
    var isLoading: Bool
    var canGoBack: Bool
    var canGoForward: Bool
    var favicon: UIImage?
    var isPinned: Bool
    var isPlayingAudio: Bool
    var isMuted: Bool
    var scrollPosition: CGFloat
    var zoomLevel: Double
    var lastAccessDate: Date
    var isSuspended: Bool
    var isPrivate: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        title: String = "New Tab",
        isLoading: Bool = false,
        canGoBack: Bool = false,
        canGoForward: Bool = false,
        favicon: UIImage? = nil,
        isPinned: Bool = false,
        isPlayingAudio: Bool = false,
        isMuted: Bool = false,
        scrollPosition: CGFloat = 0,
        zoomLevel: Double = 1.0,
        lastAccessDate: Date = .now,
        isSuspended: Bool = false,
        isPrivate: Bool = false
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.isLoading = isLoading
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.favicon = favicon
        self.isPinned = isPinned
        self.isPlayingAudio = isPlayingAudio
        self.isMuted = isMuted
        self.scrollPosition = scrollPosition
        self.zoomLevel = zoomLevel
        self.lastAccessDate = lastAccessDate
        self.isSuspended = isSuspended
        self.isPrivate = isPrivate
    }
}
