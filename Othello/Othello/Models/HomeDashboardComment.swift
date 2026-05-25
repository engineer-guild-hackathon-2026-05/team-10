import SwiftUI

struct HomeDashboardComment: Identifiable, Equatable {
    let id: String
    let howCard: HowCardComment
    let song: Song
    let artist: Artist
    let artworkURL: URL?

    init(
        howCard: HowCardComment,
        songTitle: String,
        artistName: String,
        artworkURL: URL?,
        durationSeconds: Int,
        gradientColors: [Color]
    ) {
        let song = Song(
            id: UUID(),
            title: songTitle,
            artistName: artistName,
            gradientColors: gradientColors,
            durationSeconds: durationSeconds,
            artworkURL: artworkURL
        )

        self.id = howCard.id
        self.howCard = howCard
        self.song = song
        self.artist = Artist(
            id: UUID(),
            name: artistName,
            listeningCount: "\(max(howCard.goods, 0)) reactions",
            tag: "コメント",
            gradientColors: gradientColors,
            artworkURL: artworkURL,
            songs: [song]
        )
        self.artworkURL = artworkURL
    }

    static func == (lhs: HomeDashboardComment, rhs: HomeDashboardComment) -> Bool {
        lhs.id == rhs.id
    }
}
