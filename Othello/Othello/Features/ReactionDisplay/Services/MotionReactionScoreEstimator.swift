import Foundation

enum MotionReactionScoreEstimator {
    static func score(from sample: AirPodsMotionSample) -> ReactionScore {
        let acceleration = sample.accelerationMagnitude
        let rotation = sample.rotationMagnitude
        let sway = abs(sample.rotationRate.y)
        let calmMotion = max(0, 1.0 - min(1.0, acceleration * 2.4 + rotation * 0.12))

        return ReactionScore(
            groove: clamp((acceleration * 1.25) + (sway * 0.22)),
            chill: clamp(0.24 + calmMotion * 0.52 + min(0.24, rotation * 0.03)),
            neutral: clamp(calmMotion)
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
}
