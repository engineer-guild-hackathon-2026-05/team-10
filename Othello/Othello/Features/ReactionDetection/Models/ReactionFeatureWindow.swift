import Foundation

enum MotionFeature: String, CaseIterable {
    case ax, ay, az, gx, gy, gz, pitch, roll, yaw

    init?(modelInputName: String) {
        let normalized = modelInputName.normalizedFeatureName
        if let feature = MotionFeature.allCases.first(where: { normalized == $0.rawValue }) {
            self = feature
        } else {
            return nil
        }
    }
}

struct ReactionFeatureWindow {
    let samples: [AirPodsMotionSample]
    let startTime: TimeInterval
    let endTime: TimeInterval
    let meanMagnitude: Double
    let stdMagnitude: Double
    let maxDelta: Double
    let energy: Double
    let peakCount: Int
    let rhythmRegularity: Double
    let stillness: Double

    var duration: TimeInterval {
        max(0, endTime - startTime)
    }

    func series(for feature: MotionFeature) -> [Double] {
        samples.map { sample in
            switch feature {
            case .ax: return sample.userAcceleration.x
            case .ay: return sample.userAcceleration.y
            case .az: return sample.userAcceleration.z
            case .gx: return sample.rotationRate.x
            case .gy: return sample.rotationRate.y
            case .gz: return sample.rotationRate.z
            case .pitch: return sample.attitude.pitch
            case .roll: return sample.attitude.roll
            case .yaw: return sample.attitude.yaw
            }
        }
    }

    func aggregateValue(for inputName: String) -> Double? {
        let normalized = inputName.normalizedFeatureName

        if let feature = MotionFeature(modelInputName: inputName) {
            return series(for: feature).last ?? 0
        }

        switch normalized {
        case "meanmagnitude", "magnitude", "meanmotion", "motionmean":
            return meanMagnitude
        case "stdmagnitude", "standarddeviation", "motionstd", "stdmotion":
            return stdMagnitude
        case "maxdelta", "deltamax":
            return maxDelta
        case "energy", "motionenergy":
            return energy
        case "peakcount", "peaks":
            return Double(peakCount)
        case "rhythmregularity", "regularity", "rhythm":
            return rhythmRegularity
        case "stillness", "quietness":
            return stillness
        case "windowduration", "duration":
            return duration
        default:
            return nil
        }
    }
}

struct ReactionFeatureExtractor {
    var windowDuration: TimeInterval = 2.0
    var minimumDuration: TimeInterval = 1.0

    func makeWindow(from samples: [AirPodsMotionSample]) -> ReactionFeatureWindow? {
        guard let firstSample = samples.first, let latestSample = samples.last else {
            return nil
        }

        let latestTime = playbackTime(for: latestSample, firstSample: firstSample)
        let windowSamples = samples.filter { sample in
            latestTime - playbackTime(for: sample, firstSample: firstSample) <= windowDuration
        }

        guard let startSample = windowSamples.first,
              let endSample = windowSamples.last else {
            return nil
        }

        let startTime = playbackTime(for: startSample, firstSample: firstSample)
        let endTime = playbackTime(for: endSample, firstSample: firstSample)
        guard endTime - startTime >= minimumDuration || windowSamples.count >= 40 else {
            return nil
        }

        let magnitudes = windowSamples.map { sample in
            sqrt(pow(sample.accelerationMagnitude, 2) + pow(sample.rotationMagnitude * 0.18, 2))
        }
        let mean = magnitudes.mean
        let std = magnitudes.standardDeviation(mean: mean)
        let deltas = zip(magnitudes.dropFirst(), magnitudes).map { abs($0 - $1) }
        let maxDelta = deltas.max() ?? 0
        let energy = magnitudes.map { $0 * $0 }.mean
        let peakIndexes = Self.peakIndexes(in: magnitudes, threshold: mean + (std * 0.45))
        let peakTimes = peakIndexes.map { playbackTime(for: windowSamples[$0], firstSample: firstSample) }

        return ReactionFeatureWindow(
            samples: windowSamples,
            startTime: startTime,
            endTime: endTime,
            meanMagnitude: mean,
            stdMagnitude: std,
            maxDelta: maxDelta,
            energy: energy,
            peakCount: peakIndexes.count,
            rhythmRegularity: Self.rhythmRegularity(peakTimes: peakTimes),
            stillness: Self.clamp(1 - (mean / 0.18))
        )
    }

    private func playbackTime(
        for sample: AirPodsMotionSample,
        firstSample: AirPodsMotionSample
    ) -> TimeInterval {
        sample.playbackTime ?? sample.capturedAt.timeIntervalSince(firstSample.capturedAt)
    }

    private static func peakIndexes(in magnitudes: [Double], threshold: Double) -> [Int] {
        guard magnitudes.count >= 3 else { return [] }

        return (1..<(magnitudes.count - 1)).filter { index in
            magnitudes[index] > threshold
                && magnitudes[index] > magnitudes[index - 1]
                && magnitudes[index] >= magnitudes[index + 1]
        }
    }

    private static func rhythmRegularity(peakTimes: [TimeInterval]) -> Double {
        guard peakTimes.count >= 4 else { return 0 }

        let intervals = zip(peakTimes.dropFirst(), peakTimes).map { $0 - $1 }
        let mean = intervals.mean
        guard mean > 0 else { return 0 }

        let coefficientOfVariation = intervals.standardDeviation(mean: mean) / mean
        return clamp(1 - coefficientOfVariation)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

extension Array where Element == Double {
    fileprivate var mean: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }

    fileprivate func standardDeviation(mean: Double) -> Double {
        guard count > 1 else { return 0 }
        let variance = reduce(0) { $0 + pow($1 - mean, 2) } / Double(count)
        return sqrt(variance)
    }
}

extension String {
    fileprivate var normalizedFeatureName: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
