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
            let howCards = try await FirebaseAPI.shared.fetchHowCards(songID: song.howCardLookupSongID)
            try Task.checkCancellation()
            let userProfiles = profilesByID(try await UserProfileService.fetchUsers(ids: howCards.map(\.userID)))
            try Task.checkCancellation()
            posts = howCards.map { card in
                FeedPost(
                    howCard: card,
                    song: song,
                    userProfile: userProfiles[card.userID]
                )
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Howカードを取得できませんでした"
            posts = []
        }
    }

    func updateReplyCount(cardID: String, replyCount: Int) {
        posts = posts.map { post in
            guard post.cardID == cardID else { return post }
            return post.replacingCommentCount(replyCount)
        }
    }

    private func profilesByID(_ profiles: [UserProfile]) -> [String: UserProfile] {
        Dictionary(uniqueKeysWithValues: profiles.map { ($0.userID, $0) })
    }
}
