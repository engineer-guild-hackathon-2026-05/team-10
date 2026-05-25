import Foundation

/// 同じ曲で反応した他者（マッチング相手）。how-cards 1件＝1反応として扱う。
struct ResonanceReactor: Identifiable, Equatable, Hashable {
    let id: String          // how-card id
    let userId: String
    let displayName: String
    let comment: String
    let spotStart: TimeInterval
    let spotEnd: TimeInterval
    /// 自分の反応区間と重なるか（🔥同地点）。MatchService が算出して埋める。
    var isSameSpot: Bool

    var spotLabel: String {
        let m = Int(spotStart) / 60
        let s = Int(spotStart) % 60
        return String(format: "%d:%02d", m, s)
    }
}
