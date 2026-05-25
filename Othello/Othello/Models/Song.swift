import Foundation
import SwiftUI

struct Song: Identifiable {
    let id: UUID
    let title: String
    let artistName: String
    let gradientColors: [Color]
    let durationSeconds: Int
    let artworkURL: URL?

    init(
        id: UUID,
        title: String,
        artistName: String,
        gradientColors: [Color],
        durationSeconds: Int,
        artworkURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.gradientColors = gradientColors
        self.durationSeconds = durationSeconds
        self.artworkURL = artworkURL
    }
}

extension Song: Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
