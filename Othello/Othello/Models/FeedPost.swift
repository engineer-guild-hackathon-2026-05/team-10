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
    let howCardComment: HowCardComment?
    let likeCount: Int
    let commentCount: Int

    var playbackContext: NowPlayingContext {
        if let howCardComment {
            return NowPlayingContext(song: song, howCardComment: howCardComment)
        }

        return NowPlayingContext(song: song)
    }
}

extension FeedPost {
    init(howCard: HowCardComment, song: Song, userProfile: UserProfile? = nil) {
        let displayName = FeedPost.displayName(from: howCard, userProfile: userProfile)
        let displayHandle = FeedPost.displayHandle(displayName: displayName)
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
            howCardComment: howCard,
            likeCount: howCard.goods,
            commentCount: howCard.replyCount
        )
    }

    func replacingCommentCount(_ commentCount: Int) -> FeedPost {
        let updatedHowCardComment = howCardComment?.replacingReplyCount(commentCount)
        return FeedPost(
            id: id,
            cardID: cardID,
            userName: userName,
            userHandle: userHandle,
            avatarLetter: avatarLetter,
            avatarColor: avatarColor,
            timeAgo: timeAgo,
            comment: comment,
            song: song,
            howCardComment: updatedHowCardComment,
            likeCount: likeCount,
            commentCount: commentCount
        )
    }

    private static func displayHandle(displayName: String) -> String {
        guard displayName != "listener" else {
            return "@listener"
        }

        let handle = displayName
            .replacingOccurrences(of: "\\s+", with: ".", options: .regularExpression)
        return "@\(handle)"
    }

    private static func displayName(from howCard: HowCardComment, userProfile: UserProfile?) -> String {
        normalizedDisplayName(howCard.userName) ?? normalizedDisplayName(from: userProfile) ?? "listener"
    }

    private static func normalizedDisplayName(from profile: UserProfile?) -> String? {
        normalizedDisplayName(profile?.displayName)
    }

    private static func normalizedDisplayName(_ value: String?) -> String? {
        guard let displayName = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !displayName.isEmpty else {
            return nil
        }
        return displayName
    }
}
