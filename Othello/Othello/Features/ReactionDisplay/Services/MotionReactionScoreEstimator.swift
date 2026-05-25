import Foundation

enum MotionReactionScoreEstimator {
    static func score(from sample: AirPodsMotionSample) -> ReactionScore {
        let acceleration = sample.accelerationMagnitude
        let rotation = sample.rotationMagnitude
        let nod = abs(sample.rotationRate.x)
        let sway = abs(sample.rotationRate.y)
        let turn = abs(sample.rotationRate.z)
        let pitch = abs(sample.attitude.pitch)
        let roll = abs(sample.attitude.roll)

        return ReactionScore(
            groove: clamp((acceleration * 1.25) + (sway * 0.22)),
            hype: clamp((acceleration * 1.55) + (rotation * 0.10)),
            chill: clamp(0.45 - (acceleration * 0.55) - (rotation * 0.04)),
            immersion: clamp((pitch * 0.30) + (roll * 0.16) + (nod * 0.08)),
            hit: clamp((turn * 0.14) + (acceleration * 0.70)),
            afterglow: clamp(0.20 + (1.0 - min(1.0, acceleration * 2.0)) * 0.25)
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
}
