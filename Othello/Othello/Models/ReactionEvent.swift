import SwiftUI

// FR-DETECT-02: 3状態聴取タグ
enum HowTag: String, CaseIterable, Hashable {
    case groove
    case chill
    case neutral

    var label: String {
        switch self {
        case .groove:  return "のっている"
        case .chill:   return "ちるい"
        case .neutral: return "neutral"
        }
    }

    var color: Color {
        switch self {
        case .groove:  return Color(red: 1.0, green: 0.42, blue: 0.20)
        case .chill:   return Color(red: 0.18, green: 0.68, blue: 1.0)
        case .neutral: return Color(red: 0.64, green: 0.68, blue: 0.70)
        }
    }
}

// FR-HR-02: 心拍トレンド（秒単位の断定をせずトレンドとして扱う）
enum HeartRateTrend {
    case rising, stable, falling

    var label: String {
        switch self {
        case .rising:  return "上昇"
        case .stable:  return "安定"
        case .falling: return "下降"
        }
    }

    var systemImage: String {
        switch self {
        case .rising:  return "arrow.up.right"
        case .stable:  return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .rising:  return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .stable:  return .gray
        case .falling: return Color(red: 0.2, green: 0.7, blue: 1.0)
        }
    }
}

// FR-DETECT-04: 反応区間データモデル
struct ReactionEvent: Identifiable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let intensity: Double         // 0.0〜1.0
    let tags: [HowTag]
    let lyricLine: String?        // FR-LYRIC-01: nilなら歌詞なし表示
    let lyricTranslation: String?
    let heartRateTrend: HeartRateTrend

    var duration: TimeInterval { endTime - startTime }

    // モックデータ生成
    static func mockSamples(trackDuration: TimeInterval) -> [ReactionEvent] {
        [
            ReactionEvent(
                id: UUID(), startTime: 18, endTime: 24, intensity: 0.7,
                tags: [.groove],
                lyricLine: "深夜二時の改札を抜けて",
                lyricTranslation: "Through the late-night turnstile",
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 42, endTime: 52, intensity: 1.0,
                tags: [.groove],
                lyricLine: "コンビニの灯りに泳いだ",
                lyricTranslation: "Swimming in the convenience-store glow",
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 78, endTime: 84, intensity: 0.5,
                tags: [.chill],
                lyricLine: "君のメッセージは未読のまま",
                lyricTranslation: "Your message still unread",
                heartRateTrend: .stable
            ),
            ReactionEvent(
                id: UUID(), startTime: 115, endTime: 122, intensity: 0.8,
                tags: [.groove],
                lyricLine: nil,
                lyricTranslation: nil,
                heartRateTrend: .rising
            ),
            ReactionEvent(
                id: UUID(), startTime: 188, endTime: 196, intensity: 0.6,
                tags: [.neutral],
                lyricLine: "壊れた傘を畳んでいる",
                lyricTranslation: "Folding a broken umbrella",
                heartRateTrend: .falling
            ),
        ]
    }
}
