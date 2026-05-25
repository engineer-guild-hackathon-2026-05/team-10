import SwiftUI
import Combine

@MainActor
final class MusicFeedViewModel: ObservableObject {
    let artist: Artist
    @Published var selectedSongIndex: Int = 0
    @Published private(set) var posts: [FeedPost] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    var selectedSong: Song? {
        guard artist.songs.indices.contains(selectedSongIndex) else { return nil }
        return artist.songs[selectedSongIndex]
    }

    init(artist: Artist) {
        self.artist = artist
    }

    func loadPosts() async {
        guard let song = selectedSong else {
            posts = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let howCards = try await FirebaseAPI.shared.fetchHowCards(songID: song.firestoreSongID)
            posts = howCards.map { FeedPost(howCard: $0, song: song) }
        } catch {
            errorMessage = "Howカードを取得できませんでした"
            posts = []
        }
    }
}
