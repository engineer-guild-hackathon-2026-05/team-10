import Foundation

// FR-DETECT-04: 反応区間データモデル
struct ReactionEvent: Identifiable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let intensity: Double         // 0.0〜1.0
    let tags: [HowTag]
    let score: ReactionScore
    let lyricLine: String?        // FR-LYRIC-01: nilなら歌詞なし表示
    let lyricTranslation: String?
    let heartRateTrend: HeartRateTrend

    var duration: TimeInterval { endTime - startTime }

    // モックデータ生成
    static func mockSamples(trackDuration: TimeInterval) -> [ReactionEvent] {
        [
            ReactionEvent(
                id: UUID(), startTime: 18, endTime: 24, intensity: 0.7,
                tags: [.groove], score: .empty,
                lyricLine: "深夜二時の改札を抜けて",
                lyricTranslation: "Through the late-night turnstile",
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 42, endTime: 52, intensity: 1.0,
                tags: [.hit, .immersion], score: .empty,
                lyricLine: "コンビニの灯りに泳いだ",
                lyricTranslation: "Swimming in the convenience-store glow",
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 78, endTime: 84, intensity: 0.5,
                tags: [.chill], score: .empty,
                lyricLine: "君のメッセージは未読のまま",
                lyricTranslation: "Your message still unread",
                heartRateTrend: .stable
            ),
            ReactionEvent(
                id: UUID(), startTime: 115, endTime: 122, intensity: 0.8,
                tags: [.hype, .groove], score: .empty,
                lyricLine: nil,
                lyricTranslation: nil,
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 188, endTime: 196, intensity: 0.6,
                tags: [.afterglow], score: .empty,
                lyricLine: "壊れた傘を畳んでいる",
                lyricTranslation: "Folding a broken umbrella",
                heartRateTrend: .falling
            ),
        ]
    }
}
