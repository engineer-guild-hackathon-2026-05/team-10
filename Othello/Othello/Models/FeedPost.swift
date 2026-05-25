import SwiftUI

struct FeedPost: Identifiable {
    let id: UUID
    let cardID: String?
    let userName: String
    let userHandle: String
    let avatarLetter: String
    let avatarColor: Color
    let timeAgo: String
    let comment: String
    let song: Song
    let likeCount: Int
    let commentCount: Int
}

extension FeedPost {
    init(howCard: HowCardComment, song: Song) {
        let displayHandle = FeedPost.displayHandle(from: howCard.userID)
        let displayName = FeedPost.displayName(from: howCard.userID)
        self.init(
            id: UUID(),
            cardID: howCard.documentID,
            userName: displayName,
            userHandle: displayHandle,
            avatarLetter: displayName.first.map(String.init) ?? "H",
            avatarColor: Color(red: 0.55, green: 0.35, blue: 0.85),
            timeAgo: "今",
            comment: howCard.comment,
            song: song,
            likeCount: howCard.goods,
            commentCount: 0
        )
    }

    private static func displayHandle(from userID: String) -> String {
        let handle = userID
            .replacingOccurrences(of: "seed_", with: "")
            .replacingOccurrences(of: "_", with: ".")
        return handle.isEmpty ? "@listener" : "@\(handle)"
    }

    private static func displayName(from userID: String) -> String {
        let normalized = userID
            .replacingOccurrences(of: "seed_", with: "")
            .replacingOccurrences(of: "_", with: " ")
        guard let firstWord = normalized.split(separator: " ").first else {
            return "listener"
        }
        return String(firstWord)
    }
}
