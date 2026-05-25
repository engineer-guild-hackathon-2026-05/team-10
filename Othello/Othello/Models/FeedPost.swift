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
        let shortUserID = String(howCard.userID.prefix(6))
        self.init(
            id: UUID(),
            cardID: howCard.documentID,
            userName: shortUserID.isEmpty ? "listener" : "user \(shortUserID)",
            userHandle: shortUserID.isEmpty ? "@listener" : "@\(shortUserID)",
            avatarLetter: shortUserID.first.map(String.init) ?? "H",
            avatarColor: Color(red: 0.55, green: 0.35, blue: 0.85),
            timeAgo: "今",
            comment: howCard.comment,
            song: song,
            likeCount: howCard.goods,
            commentCount: 0
        )
    }

    static func mockPosts(for song: Song) -> [FeedPost] {
        let comments: [(String, String, String, Color, String, Int, Int)] = [
            ("みお", "@mio_x", "今日ずっと聴いてる。サビが沁みる。", Color(red: 0.9, green: 0.4, blue: 0.4), "今", 142, 12),
            ("ren", "@ren.fm", "雨の朝にぴったり🎵", Color(red: 0.4, green: 0.5, blue: 0.9), "4分前", 88, 7),
            ("Sora", "@sora_24", "ドライブBGM決定。", Color(red: 0.5, green: 0.8, blue: 0.5), "12分前", 231, 24),
            ("hana", "@hana_music", "このメロディ反則すぎる…", Color(red: 0.85, green: 0.55, blue: 0.35), "18分前", 67, 5),
            ("kai", "@kai_waves", "この曲で泣いた笑", Color(red: 0.55, green: 0.35, blue: 0.85), "32分前", 304, 41),
            ("yuki", "@yuki_beats", "何回でも聴ける。", Color(red: 0.35, green: 0.7, blue: 0.75), "1時間前", 189, 18)
        ]
        return comments.map { (name, handle, comment, color, time, likes, comments) in
            FeedPost(
                id: UUID(),
                cardID: nil,
                userName: name,
                userHandle: handle,
                avatarLetter: String(name.prefix(1)),
                avatarColor: color,
                timeAgo: time,
                comment: comment,
                song: song,
                likeCount: likes,
                commentCount: comments
            )
        }
    }
}
