import SwiftUI
import Combine

@MainActor
final class MusicFeedViewModel: ObservableObject {
    let artist: Artist
    @Published var selectedSongIndex: Int = -1

    var selectedSong: Song? {
        guard artist.songs.indices.contains(selectedSongIndex) else { return nil }
        return artist.songs[selectedSongIndex]
    }

    var posts: [FeedPost] {
        if let song = selectedSong {
            return FeedPost.mockPosts(for: song)
        }
        return artist.songs.flatMap { FeedPost.mockPosts(for: $0) }
    }

    init(artist: Artist) {
        self.artist = artist
    }
}
