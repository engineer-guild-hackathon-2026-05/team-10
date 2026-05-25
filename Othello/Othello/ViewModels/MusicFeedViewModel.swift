import SwiftUI
import Combine

@MainActor
final class MusicFeedViewModel: ObservableObject {
    let artist: Artist
    @Published var selectedSongIndex: Int = 0

    var selectedSong: Song { artist.songs[selectedSongIndex] }

    var posts: [FeedPost] { FeedPost.mockPosts(for: selectedSong) }

    init(artist: Artist) {
        self.artist = artist
    }
}
