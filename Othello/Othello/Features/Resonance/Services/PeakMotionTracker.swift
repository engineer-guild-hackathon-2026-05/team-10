import Foundation

/// AirPods サンプル列から「一番動いた瞬間」を抽出する純ロジック。
/// ML を使わず interactionIntensity の最大値を採用する（FR-RES-01）。
enum PeakMotionTracker {
    /// しきい値: これ未満のピークはノイズとみなし無視する。
    static let minimumIntensity: Double = 0.12

    /// samples からピーク瞬間を求める。playbackTime を持つサンプルを優先する。
    static func peak(from samples: [AirPodsMotionSample]) -> PeakMoment? {
        guard !samples.isEmpty else { return nil }

        let best = samples.max { lhs, rhs in
            lhs.interactionIntensity < rhs.interactionIntensity
        }

        guard let best, best.interactionIntensity >= minimumIntensity else { return nil }

        let time = best.playbackTime ?? elapsedFallback(for: best, in: samples)
        return PeakMoment(playbackTime: time, intensity: min(1.0, best.interactionIntensity))
    }

    /// playbackTime が無い場合は、最初のサンプルからの経過秒で代用する。
    private static func elapsedFallback(for sample: AirPodsMotionSample, in samples: [AirPodsMotionSample]) -> TimeInterval {
        guard let first = samples.first else { return 0 }
        return max(0, sample.capturedAt.timeIntervalSince(first.capturedAt))
    }
}
