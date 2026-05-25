import Foundation

enum HowCardSeedService {
    private struct FeedCommentTemplate {
        let comment: String
        let songStart: TimeInterval
        let songEnd: TimeInterval
    }

    private struct CommunityCommentTemplate {
        let artistName: String
        let songTitle: String
        let comment: String
        let songStart: TimeInterval
        let songEnd: TimeInterval
    }

    @discardableResult
    static func seedIfNeeded() async throws -> Int {
        let seedCards = makeSeedCards()
        let existingCards = try await FirebaseAPI.shared.fetchHowCards(limit: 250)
        var existingKeys = Set(existingCards.map(seedKey))
        var createdCount = 0

        for card in seedCards {
            let key = seedKey(for: card.comment, songID: card.songID, songStart: card.songStart, songEnd: card.songEnd)
            guard !existingKeys.contains(key) else { continue }

            _ = try await FirebaseAPI.shared.createHowCard(card)
            existingKeys.insert(key)
            createdCount += 1
        }

        return createdCount
    }

    private static func makeSeedCards() -> [HowCardComment] {
        let feedCards = Artist.catalog.flatMap { artist in
            artist.songs.flatMap { song in
                feedTemplates.map { template in
                    HowCardComment(
                        comment: template.comment,
                        songStart: template.songStart,
                        songEnd: template.songEnd,
                        songID: song.firestoreSongID,
                        artistID: song.firestoreArtistID
                    )
                }
            }
        }

        let communityCards = communityTemplates.map { template in
            let artistID = stableIdentifier(from: template.artistName)
            return HowCardComment(
                comment: template.comment,
                songStart: template.songStart,
                songEnd: template.songEnd,
                songID: "\(artistID)-\(stableIdentifier(from: template.songTitle))",
                artistID: artistID
            )
        }

        return feedCards + communityCards
    }

    private static let feedTemplates: [FeedCommentTemplate] = [
        FeedCommentTemplate(comment: "今日ずっと聴いてる。サビが沁みる。", songStart: 12, songEnd: 20),
        FeedCommentTemplate(comment: "雨の朝にぴったり🎵", songStart: 30, songEnd: 38),
        FeedCommentTemplate(comment: "ドライブBGM決定。", songStart: 48, songEnd: 56),
        FeedCommentTemplate(comment: "このメロディ反則すぎる…", songStart: 66, songEnd: 74),
        FeedCommentTemplate(comment: "この曲で泣いた笑", songStart: 84, songEnd: 92),
        FeedCommentTemplate(comment: "何回でも聴ける。", songStart: 102, songEnd: 110)
    ]

    private static let communityTemplates: [CommunityCommentTemplate] = [
        CommunityCommentTemplate(
            artistName: "米津玄師",
            songTitle: "感電",
            comment: "歌詞の映像喚起力に完全に引き込まれた。コンビニの灯りの描写が刺さりすぎた。",
            songStart: 24,
            songEnd: 34
        ),
        CommunityCommentTemplate(
            artistName: "米津玄師",
            songTitle: "感電",
            comment: "イントロから頭が動いてしまう。ビートとベースラインの絡みが最高。",
            songStart: 24,
            songEnd: 34
        ),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "感電", comment: "この歌詞で泣いた", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "YOASOBI", songTitle: "夜に駆ける", comment: "深夜ドライブに最高", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "感電", comment: "ビートに乗れて最高", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "Lemon", comment: "歌詞の世界に入り込む", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "感電", comment: "余韻が抜けない", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "打上花火", comment: "テンションが爆上がり", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(artistName: "米津玄師", songTitle: "感電", comment: "心が落ち着く", songStart: 24, songEnd: 34),
        CommunityCommentTemplate(
            artistName: "RADWIMPS",
            songTitle: "愛にできることはまだあるかい",
            comment: "この一節が全部",
            songStart: 24,
            songEnd: 34
        )
    ]

    private static func seedKey(_ card: HowCardComment) -> String {
        seedKey(for: card.comment, songID: card.songID, songStart: card.songStart, songEnd: card.songEnd)
    }

    private static func seedKey(
        for comment: String,
        songID: String,
        songStart: TimeInterval,
        songEnd: TimeInterval
    ) -> String {
        "\(songID)|\(Int(songStart * 10))|\(Int(songEnd * 10))|\(comment)"
    }

    private static func stableIdentifier(from value: String) -> String {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9\\-ぁ-んァ-ン一-龥ー&.]", with: "", options: .regularExpression)
        return normalized.isEmpty ? "unknown" : normalized
    }
}
