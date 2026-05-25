import SwiftUI

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
