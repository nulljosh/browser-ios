import Foundation

struct HistoryEntry: Identifiable, Codable {
    let id: UUID
    let url: URL
    var title: String
    let visitDate: Date

    init(
        id: UUID = UUID(),
        url: URL,
        title: String,
        visitDate: Date = .now
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.visitDate = visitDate
    }
}
