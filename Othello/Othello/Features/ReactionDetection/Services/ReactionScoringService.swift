import Foundation

struct ReactionScoringService {
    static func score(
        for window: ReactionFeatureWindow,
        prediction: ActivityPrediction?
    ) -> ReactionScore {
        let movement = max(
            normalize(window.meanMagnitude, low: 0.004, high: 0.085),
            normalize(window.stdMagnitude, low: 0.004, high: 0.080)
        )
        let energy = normalize(window.energy, low: 0.00002, high: 0.008)
        let abrupt = normalize(window.maxDelta, low: 0.008, high: 0.14)
        let rhythm = window.rhythmRegularity
        let stillness = window.stillness

        return ReactionScore(
            groove: weighted([modelProbability("groove", prediction), rhythm, movement], [0.55, 0.3, 0.15]),
            chill: weighted([modelProbability("chill", prediction), stillness, 1 - energy], [0.55, 0.3, 0.15]),
            neutral: weighted([modelProbability("neutral", prediction), stillness, 1 - movement, 1 - abrupt], [0.48, 0.22, 0.18, 0.12])
        ).clamped()
    }

    static func manualScore(for tag: HowTag) -> ReactionScore {
        switch tag {
        case .groove:
            return ReactionScore(groove: 1, chill: 0.05, neutral: 0.02)
        case .chill:
            return ReactionScore(groove: 0.05, chill: 1, neutral: 0.10)
        case .neutral:
            return ReactionScore(groove: 0.02, chill: 0.08, neutral: 1)
        }
    }

    private static func modelProbability(
        _ label: String,
        _ prediction: ActivityPrediction?
    ) -> Double {
        guard let prediction else { return 0 }

        let target = label.normalizedScoreLabel
        return prediction.probabilities.first { key, _ in
            key.normalizedScoreLabel == target
        }?.value ?? (prediction.label?.normalizedScoreLabel == target ? 1 : 0)
    }

    private static func normalize(_ value: Double, low: Double, high: Double) -> Double {
        guard high > low else { return 0 }
        return clamp((value - low) / (high - low))
    }

    private static func weighted(_ values: [Double], _ weights: [Double]) -> Double {
        zip(values, weights).reduce(0) { $0 + ($1.0 * $1.1) }
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

extension ReactionScore {
    var intensity: Double {
        axes.map(\.value).max() ?? 0
    }

    func blended(with next: ReactionScore, factor: Double) -> ReactionScore {
        let f = min(max(factor, 0), 1)
        let keep = 1 - f

        return ReactionScore(
            groove: (groove * keep) + (next.groove * f),
            chill: (chill * keep) + (next.chill * f),
            neutral: (neutral * keep) + (next.neutral * f)
        ).clamped()
    }

    func activeTags(threshold: Double = 0.42) -> [HowTag] {
        axes.compactMap { axis in
            guard axis.value >= threshold else { return nil }
            return HowTag(rawValue: axis.id)
        }
    }

    fileprivate func clamped() -> ReactionScore {
        ReactionScore(
            groove: clampScore(groove),
            chill: clampScore(chill),
            neutral: clampScore(neutral)
        )
    }

    private func clampScore(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

extension String {
    fileprivate var normalizedScoreLabel: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
