import Foundation
import SwiftUI

/// 3状態聴取スコア
struct ReactionScore: Equatable {
    var groove: Double = 0
    var chill: Double = 0
    var neutral: Double = 0

    static let empty = ReactionScore()

    var axes: [ReactionAxis] {
        [
            ReactionAxis(id: "groove", label: "のっている", emoji: "🎵", value: groove, color: HowTag.groove.color),
            ReactionAxis(id: "chill", label: "ちるい", emoji: "❄️", value: chill, color: HowTag.chill.color),
            ReactionAxis(id: "neutral", label: "neutral", emoji: "○", value: neutral, color: HowTag.neutral.color)
        ]
    }

    /// 最も強い状態
    var dominant: ReactionAxis? {
        axes.max(by: { $0.value < $1.value }).flatMap { $0.value > 0.1 ? $0 : nil }
    }

    var dominantTag: HowTag {
        let values: [(HowTag, Double)] = [
            (.groove, groove),
            (.chill, chill),
            (.neutral, neutral)
        ]
        return values.max(by: { $0.1 < $1.1 })?.0 ?? .neutral
    }
}

struct ReactionAxis: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let value: Double  // 0.0 〜 1.0
    let color: Color
}
