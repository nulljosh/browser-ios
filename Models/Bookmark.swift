import Foundation

struct Bookmark: Identifiable, Codable {
    let id: UUID
    let url: URL
    var title: String
    let dateAdded: Date
    var folder: String

    init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        dateAdded: Date = .now,
        folder: String = "Bookmarks"
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.dateAdded = dateAdded
        self.folder = folder
    }
}
