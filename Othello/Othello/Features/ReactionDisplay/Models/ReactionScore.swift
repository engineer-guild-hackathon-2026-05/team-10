import Foundation
import SwiftUI

/// 6軸聴取状態スコア（マルチラベル＝同時複数可）
struct ReactionScore: Equatable {
    var groove: Double = 0     // ノってる
    var hype: Double = 0       // 上がった
    var chill: Double = 0      // チル
    var immersion: Double = 0  // 聴き入り
    var hit: Double = 0        // 刺さった
    var afterglow: Double = 0  // 余韻

    static let empty = ReactionScore()

    var axes: [ReactionAxis] {
        [
            ReactionAxis(id: "groove", label: "ノってる", emoji: "🎵", value: groove, color: HowTag.groove.color),
            ReactionAxis(id: "hype", label: "上がった", emoji: "🔥", value: hype, color: HowTag.hype.color),
            ReactionAxis(id: "chill", label: "チル", emoji: "❄️", value: chill, color: HowTag.chill.color),
            ReactionAxis(id: "immersion", label: "聴き入り", emoji: "🎧", value: immersion, color: HowTag.immersion.color),
            ReactionAxis(id: "hit", label: "刺さった", emoji: "💫", value: hit, color: HowTag.hit.color),
            ReactionAxis(id: "afterglow", label: "余韻", emoji: "✨", value: afterglow, color: HowTag.afterglow.color),
        ]
    }

    /// 最も強い軸（dominant state）
    var dominant: ReactionAxis? {
        axes.max(by: { $0.value < $1.value }).flatMap { $0.value > 0.1 ? $0 : nil }
    }

    var dominantTag: HowTag {
        let values: [(HowTag, Double)] = [
            (.groove, groove),
            (.hype, hype),
            (.chill, chill),
            (.immersion, immersion),
            (.hit, hit),
            (.afterglow, afterglow)
        ]
        return values.max(by: { $0.1 < $1.1 })?.0 ?? .neutral
    }
}

extension ReactionScore {
    var asDictionary: [String: Double] {
        Dictionary(uniqueKeysWithValues: axes.map { ($0.id, $0.value) })
    }
}

struct ReactionAxis: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let value: Double  // 0.0 〜 1.0
    let color: Color
}
