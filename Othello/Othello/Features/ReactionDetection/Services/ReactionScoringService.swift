import Foundation

struct ReactionScoringService {
    static func score(
        for window: ReactionFeatureWindow,
        prediction: ActivityPrediction?
    ) -> ReactionScore {
        let movement = normalize(window.meanMagnitude, low: 0.015, high: 0.22)
        let variation = normalize(window.stdMagnitude, low: 0.01, high: 0.12)
        let energy = normalize(window.energy, low: 0.002, high: 0.08)
        let abrupt = normalize(window.maxDelta, low: 0.02, high: 0.22)
        let peaks = min(Double(window.peakCount) / 7, 1)
        let rhythm = window.rhythmRegularity
        let stillness = window.stillness

        var score = ReactionScore(
            groove: weighted([modelProbability("groove", prediction), rhythm, movement], [0.55, 0.3, 0.15]),
            hype: weighted([energy, peaks, abrupt], [0.45, 0.35, 0.2]),
            chill: weighted([modelProbability("chill", prediction), stillness, 1 - energy], [0.55, 0.3, 0.15]),
            immersion: weighted([modelProbability("immersion", prediction), stillness, 1 - variation], [0.6, 0.25, 0.15]),
            hit: weighted([abrupt, peaks, energy], [0.55, 0.25, 0.2]),
            afterglow: weighted([stillness, 1 - movement, 1 - abrupt], [0.45, 0.35, 0.2])
        )

        if score.afterglow > 0.55 && max(score.hype, score.hit) > 0.45 {
            score.afterglow *= 0.65
        }

        return score.clamped()
    }

    static func manualScore(for tag: HowTag) -> ReactionScore {
        switch tag {
        case .groove:
            return ReactionScore(groove: 1, hype: 0.25)
        case .hype:
            return ReactionScore(groove: 0.25, hype: 1, hit: 0.2)
        case .chill:
            return ReactionScore(chill: 1, afterglow: 0.35)
        case .immersion:
            return ReactionScore(chill: 0.15, immersion: 1, afterglow: 0.25)
        case .hit:
            return ReactionScore(hype: 0.25, immersion: 0.35, hit: 1)
        case .afterglow:
            return ReactionScore(chill: 0.35, immersion: 0.25, afterglow: 1)
        case .neutral:
            return .empty
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
            hype: (hype * keep) + (next.hype * f),
            chill: (chill * keep) + (next.chill * f),
            immersion: (immersion * keep) + (next.immersion * f),
            hit: (hit * keep) + (next.hit * f),
            afterglow: (afterglow * keep) + (next.afterglow * f)
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
            hype: clampScore(hype),
            chill: clampScore(chill),
            immersion: clampScore(immersion),
            hit: clampScore(hit),
            afterglow: clampScore(afterglow)
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
