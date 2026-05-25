import Foundation

/// 共鳴演出の表現設定（FR-RES-05）。
/// richMode = true で粒子数・グローを増やしたリッチ版、false で確実に軽い版。
enum ResonanceVisualConfig {
    /// 既定はリッチ版。重い端末で問題があれば false に。
    static let richMode = true

    static var particleCount: Int { richMode ? 120 : 48 }
    static var emberCount: Int { richMode ? 80 : 32 }
    /// 1サイクルの長さ（秒）。量子→収束→発熱→発火。
    static let cycleDuration: Double = 2.6
}
