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
    init(howCard: HowCardComment, song: Song, userProfile: UserProfile? = nil) {
        let displayName = FeedPost.displayName(from: userProfile)
        let displayHandle = FeedPost.displayHandle(from: userProfile)
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

    private static func displayHandle(from profile: UserProfile?) -> String {
        guard let displayName = normalizedDisplayName(from: profile) else {
            return "@listener"
        }

        let handle = displayName
            .replacingOccurrences(of: "\\s+", with: ".", options: .regularExpression)
        return "@\(handle)"
    }

    private static func displayName(from profile: UserProfile?) -> String {
        normalizedDisplayName(from: profile) ?? "listener"
    }

    private static func normalizedDisplayName(from profile: UserProfile?) -> String? {
        guard let displayName = profile?.displayName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !displayName.isEmpty else {
            return nil
        }
        return displayName
    }
}
