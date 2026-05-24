import Foundation

struct MotionFeatures: Codable {
    var meanMagnitude: Double
    var stdMagnitude: Double
    var meanDelta: Double
    var maxDelta: Double
    var energy: Double
    var peakCount: Double
    var rhythmRegularity: Double
    var stillness: Double
    var previousEnergyDiff: Double
    var windowDurationSec: Double

    var vector: [Double] {
        [
            meanMagnitude,
            stdMagnitude,
            meanDelta,
            maxDelta,
            energy,
            peakCount,
            rhythmRegularity,
            stillness,
            previousEnergyDiff,
            windowDurationSec
        ]
    }
}

struct TrainingExample: Codable {
    struct Labels: Codable {
        var groove: Int
        var hype: Int
        var chill: Int
        var immersion: Int
        var hit: Int
        var afterglow: Int
    }

    struct Meta: Codable {
        var phonePosition: String
        var dominantHand: String
        var usualMovement: String
        var device: String
    }

    var id: String
    var sessionId: String
    var songId: String
    var windowStart: Double
    var windowEnd: Double
    var features: [Double]
    var labels: Labels
    var meta: Meta
}

enum FeatureExtractor {
    static func makeTrainingExamples(
        from collected: CollectedSession,
        windowDurationSec: Double = 3,
        strideSec: Double = 1
    ) -> [TrainingExample] {
        let windows = extractWindows(
            samples: collected.samples,
            windowDurationSec: windowDurationSec,
            strideSec: strideSec,
            normalize: true
        )

        return windows
            .filter { !isNoiseWindow($0, labels: collected.labels) }
            .map { window in
                let labels = labelsForWindow(
                    start: window.start,
                    end: window.end,
                    labelEvents: collected.labels
                )
                return TrainingExample(
                    id: "\(collected.session.id)_\(format(window.start))_\(format(window.end))",
                    sessionId: collected.session.id,
                    songId: collected.session.songId,
                    windowStart: window.start,
                    windowEnd: window.end,
                    features: window.features,
                    labels: labels,
                    meta: TrainingExample.Meta(
                        phonePosition: collected.session.listeningContext.phonePosition.rawValue,
                        dominantHand: collected.session.listeningContext.dominantHand.rawValue,
                        usualMovement: collected.session.listeningContext.usualMovement.rawValue,
                        device: collected.session.device.model
                    )
                )
            }
    }

    private struct FeatureWindow {
        var start: Double
        var end: Double
        var rawFeatures: MotionFeatures
        var features: [Double]
    }

    private static func extractWindows(
        samples: [MotionSample],
        windowDurationSec: Double,
        strideSec: Double,
        normalize: Bool
    ) -> [FeatureWindow] {
        let sorted = samples.sorted { $0.t < $1.t }
        guard let first = sorted.first?.t, let last = sorted.last?.t, sorted.count >= 2 else {
            return []
        }

        var previousEnergy = 0.0
        var windows: [FeatureWindow] = []
        var start = first

        while start + windowDurationSec <= last + 0.0001 {
            let end = start + windowDurationSec
            let windowSamples = sorted.filter { $0.t >= start && $0.t < end }

            if windowSamples.count >= 2 {
                let raw = calculateFeatures(
                    samples: windowSamples,
                    previousEnergy: previousEnergy,
                    windowDurationSec: windowDurationSec
                )
                previousEnergy = raw.energy
                windows.append(
                    FeatureWindow(
                        start: rounded(start),
                        end: rounded(end),
                        rawFeatures: raw,
                        features: raw.vector
                    )
                )
            }

            start += strideSec
        }

        guard normalize else { return windows }
        return normalizeWindows(windows, nominalWindowDuration: windowDurationSec)
    }

    private static func calculateFeatures(
        samples: [MotionSample],
        previousEnergy: Double,
        windowDurationSec: Double
    ) -> MotionFeatures {
        let magnitudes = samples.map { sample in
            sqrt(sample.ax * sample.ax + sample.ay * sample.ay + sample.az * sample.az)
        }
        let deltas = magnitudes.enumerated().map { index, value in
            index == 0 ? 0 : abs(value - magnitudes[index - 1])
        }
        let peaks = peakIndexes(deltas)
        let peakIntervals = peaks.dropFirst().enumerated().compactMap { index, peakIndex in
            let previousPeak = peaks[index]
            guard samples.indices.contains(peakIndex), samples.indices.contains(previousPeak) else {
                return nil
            }
            return samples[peakIndex].t - samples[previousPeak].t
        }.filter { $0 > 0 }

        let meanMagnitude = mean(magnitudes)
        let stdMagnitude = stddev(magnitudes, mean: meanMagnitude)
        let meanDelta = mean(deltas)
        let maxDelta = deltas.max() ?? 0
        let energy = deltas.reduce(0) { $0 + $1 * $1 }
        let energyPerSec = energy / max(windowDurationSec, 0.0001)
        let stillness = clamp01((1 - meanDelta / 0.35) * (1 - energyPerSec / 2.5))

        return MotionFeatures(
            meanMagnitude: meanMagnitude,
            stdMagnitude: stdMagnitude,
            meanDelta: meanDelta,
            maxDelta: maxDelta,
            energy: energy,
            peakCount: Double(peaks.count),
            rhythmRegularity: rhythmRegularity(peakIntervals),
            stillness: stillness,
            previousEnergyDiff: energy - previousEnergy,
            windowDurationSec: windowDurationSec
        )
    }

    private static func normalizeWindows(
        _ windows: [FeatureWindow],
        nominalWindowDuration: Double
    ) -> [FeatureWindow] {
        guard !windows.isEmpty else { return [] }
        let rawVectors = windows.map { $0.rawFeatures.vector }
        let featureCount = rawVectors.first?.count ?? 0

        return windows.map { window in
            var normalized: [Double] = []
            for index in 0..<featureCount {
                if index == featureCount - 1 {
                    normalized.append(window.rawFeatures.windowDurationSec / nominalWindowDuration)
                    continue
                }

                let values = rawVectors.map { $0[index] }
                let featureMean = mean(values)
                let featureStd = max(stddev(values, mean: featureMean), 0.0001)
                normalized.append((window.rawFeatures.vector[index] - featureMean) / featureStd)
            }

            return FeatureWindow(
                start: window.start,
                end: window.end,
                rawFeatures: window.rawFeatures,
                features: normalized
            )
        }
    }

    private static func labelsForWindow(
        start: Double,
        end: Double,
        labelEvents: [LabelEvent]
    ) -> TrainingExample.Labels {
        var result = TrainingExample.Labels(
            groove: 0,
            hype: 0,
            chill: 0,
            immersion: 0,
            hit: 0,
            afterglow: 0
        )
        let duration = end - start

        for event in labelEvents where event.label.trainingLabel {
            let ratio = overlap(start, end, event.startedAtSec, event.endedAtSec) / max(duration, 0.0001)
            let threshold = event.label == .hit ? 0.3 : 0.5
            guard ratio >= threshold else { continue }

            switch event.label {
            case .groove: result.groove = 1
            case .hype: result.hype = 1
            case .chill: result.chill = 1
            case .immersion: result.immersion = 1
            case .hit: result.hit = 1
            case .afterglow: result.afterglow = 1
            default: break
            }
        }

        return result
    }

    private static func isNoiseWindow(_ window: FeatureWindow, labels: [LabelEvent]) -> Bool {
        labels.contains { event in
            guard event.label == .noise || event.label == .phoneOnTable else { return false }
            let ratio = overlap(window.start, window.end, event.startedAtSec, event.endedAtSec) / max(window.end - window.start, 0.0001)
            return ratio >= 0.5
        }
    }

    private static func peakIndexes(_ values: [Double]) -> [Int] {
        guard values.count >= 3 else { return [] }
        let valueMean = mean(values)
        let threshold = valueMean + stddev(values, mean: valueMean) * 0.5
        var indexes: [Int] = []

        for index in 1..<(values.count - 1) {
            let value = values[index]
            if value >= threshold && value >= values[index - 1] && value > values[index + 1] {
                indexes.append(index)
            }
        }

        return indexes
    }

    private static func rhythmRegularity(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }
        let intervalMean = mean(intervals)
        let variance = intervals.reduce(0) { $0 + pow($1 - intervalMean, 2) } / Double(intervals.count)
        return clamp01(1 - variance / (intervalMean * intervalMean + 0.0001))
    }

    private static func overlap(_ aStart: Double, _ aEnd: Double, _ bStart: Double, _ bEnd: Double) -> Double {
        max(0, min(aEnd, bEnd) - max(aStart, bStart))
    }

    private static func mean(_ values: [Double]) -> Double {
        values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
    }

    private static func stddev(_ values: [Double], mean: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        return sqrt(variance)
    }

    private static func clamp01(_ value: Double) -> Double {
        max(0, min(1, value.isFinite ? value : 0))
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

