import Foundation

/// デモ用の共鳴設定。seed スクリプト（functions/scripts/seed-resonance.js）と
/// マッチング購読が同じ song_id を参照することで、実機1台でもリアルタイム共鳴を再現する。
/// 本番で実曲に紐づける場合は、投稿時の song_id をここに合わせる。
enum ResonanceDemo {
    /// マッチング購読・seed が共有する曲 ID。
    static let songId = "howtune-demo-song"
}
