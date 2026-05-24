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
            ReactionAxis(id: "groove",    label: "ノってる",  emoji: "🎵", value: groove,    color: Color(red: 1.0, green: 0.55, blue: 0.1)),
            ReactionAxis(id: "hype",      label: "上がった",  emoji: "🔥", value: hype,      color: Color(red: 1.0, green: 0.3,  blue: 0.3)),
            ReactionAxis(id: "chill",     label: "チル",      emoji: "❄️", value: chill,     color: Color(red: 0.3, green: 0.7,  blue: 1.0)),
            ReactionAxis(id: "immersion", label: "聴き入り",  emoji: "🎧", value: immersion,  color: Color(red: 0.6, green: 0.4,  blue: 1.0)),
            ReactionAxis(id: "hit",       label: "刺さった",  emoji: "💫", value: hit,        color: Color(red: 1.0, green: 0.85, blue: 0.2)),
            ReactionAxis(id: "afterglow", label: "余韻",      emoji: "✨", value: afterglow,  color: Color(red: 0.8, green: 0.5,  blue: 1.0)),
        ]
    }

    /// 最も強い軸（dominant state）
    var dominant: ReactionAxis? {
        axes.max(by: { $0.value < $1.value }).flatMap { $0.value > 0.1 ? $0 : nil }
    }
}

struct ReactionAxis: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let value: Double  // 0.0 〜 1.0
    let color: Color
}
