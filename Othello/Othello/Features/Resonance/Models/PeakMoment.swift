import Foundation

/// 再生セッション中に「一番動いた」瞬間。
/// ML を回さず、AirPods サンプルの interactionIntensity ピークから決める（決めうち）。
struct PeakMoment: Equatable {
    /// 楽曲再生位置（秒）。
    let playbackTime: TimeInterval
    /// その瞬間の反応強度（0.0〜1.0）。
    let intensity: Double

    /// M:SS 形式の表示用文字列。
    var formattedTime: String {
        let safe = max(0, playbackTime)
        let m = Int(safe) / 60
        let s = Int(safe) % 60
        return String(format: "%d:%02d", m, s)
    }

    /// マッチング・Howカード投稿に使う反応区間（ピーク前後に少し幅を持たせる）。
    func interval(spread: TimeInterval = 2.0, trackDuration: TimeInterval? = nil) -> (start: TimeInterval, end: TimeInterval) {
        let start = max(0, playbackTime - spread)
        var end = playbackTime + spread
        if let trackDuration { end = min(end, trackDuration) }
        return (start, max(end, start + 1))
    }
}
