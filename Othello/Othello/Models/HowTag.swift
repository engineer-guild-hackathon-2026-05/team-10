import SwiftUI

// FR-DETECT-02: 6軸聴取状態タグ + 波形待機状態
enum HowTag: String, CaseIterable, Hashable {
    case groove, hype, chill, immersion, hit, afterglow, neutral

    static var scoreCases: [HowTag] {
        [.groove, .hype, .chill, .immersion, .hit, .afterglow]
    }

    var label: String {
        switch self {
        case .groove:    return "groove"
        case .hype:      return "hype"
        case .chill:     return "chill"
        case .immersion: return "immersion"
        case .hit:       return "hit"
        case .afterglow: return "afterglow"
        case .neutral:   return "neutral"
        }
    }

    var color: Color {
        switch self {
        case .groove:    return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .hype:      return Color(red: 1.0, green: 0.55, blue: 0.1)
        case .chill:     return Color(red: 0.2, green: 0.7, blue: 1.0)
        case .immersion: return Color(red: 0.6, green: 0.3, blue: 1.0)
        case .hit:       return Color(red: 1.0, green: 0.2, blue: 0.5)
        case .afterglow: return Color(red: 0.9, green: 0.75, blue: 0.3)
        case .neutral:   return Color(red: 0.64, green: 0.68, blue: 0.70)
        }
    }
}
