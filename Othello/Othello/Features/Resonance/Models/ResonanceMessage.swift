import Foundation

/// リアルタイム DM の1メッセージ（FR-RES-06）。
struct ResonanceMessage: Identifiable, Equatable {
    let id: String
    let senderId: String
    let text: String
    let createdAt: Date
    /// 楽観的更新中（送信完了前）か。
    var isPending: Bool = false
}
