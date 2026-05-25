import SwiftUI

struct Song: Identifiable {
    let id: UUID
    let title: String
    let artistName: String
    let gradientColors: [Color]
    let durationSeconds: Int
}

extension Song: Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
