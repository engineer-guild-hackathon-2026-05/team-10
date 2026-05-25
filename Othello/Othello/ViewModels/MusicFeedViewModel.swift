import SwiftUI
import Combine

@MainActor
final class MusicFeedViewModel: ObservableObject {
    let artist: Artist
    @Published var selectedSongIndex: Int = 0

    var selectedSong: Song? {
        guard !artist.songs.isEmpty else { return nil }
        return artist.songs[selectedSongIndex]
    }

    var posts: [FeedPost] {
        guard let song = selectedSong else { return [] }
        return FeedPost.mockPosts(for: song)
    }

    init(artist: Artist) {
        self.artist = artist
    }
}
