import Accelerate
import CoreGraphics
import Foundation

struct AudioMotionSpectrumAnalyzer {
    static let binCount = 128
    private static let fftSetup: FFTSetup? = {
        let log2Count = vDSP_Length(log2(Double(binCount)))
        return vDSP_create_fftsetup(log2Count, FFTRadix(kFFTRadix2))
    }()
    private static let twoPi = CGFloat.pi * 2

    static func amplitudes(
        playbackTime: TimeInterval,
        isPlaying: Bool,
        audioLevel: Double,
        motionIntensity: Double,
        trackSeed: Int,
        count: Int = binCount
    ) -> [CGFloat] {
        guard count > 0 else { return [] }

        let audio = Float(clamp(audioLevel))
        let motion = Float(clamp(motionIntensity))

        guard isPlaying else {
            let idleLevel = CGFloat(0.035 + motion * 0.10)
            return Array(repeating: idleLevel, count: count)
        }

        let signal = makeSignal(
            sampleCount: binCount,
            playbackTime: Float(playbackTime),
            audioLevel: audio,
            motionIntensity: motion,
            trackSeed: trackSeed
        )
        let magnitudes = fftMagnitudes(signal)
        guard !magnitudes.isEmpty else {
            return Array(repeating: CGFloat(0.08 + motion * 0.20), count: count)
        }

        let usableBins = max(2, magnitudes.count / 2)
        let peak = CGFloat(max(magnitudes.dropFirst().prefix(usableBins - 1).max() ?? 0.0001, 0.0001))
        let audioLevel = CGFloat(audio)
        let motionLevel = CGFloat(motion)
        let seed = abs(trackSeed)
        let seedPhase = CGFloat(seed % 10_000) / 10_000
        let time = CGFloat(playbackTime)
        let primaryCenter = wrapUnit(seedPhase + time * CGFloat(0.040 + Double(seed % 17) * 0.0014))
        let secondaryCenter = wrapUnit(seedPhase * 0.61 + 0.37 - time * CGFloat(0.028 + Double(seed % 11) * 0.0014))
        let shimmerCenter = wrapUnit(seedPhase * 0.23 + time * CGFloat(0.066 + Double(seed % 7) * 0.0026))

        let values = (0..<count).map { index in
            let progress = CGFloat(index) / CGFloat(count)
            let angle = progress * twoPi
            let spectralPhase = angle * CGFloat(1 + (seed % 4)) + time * (0.40 + audioLevel * 0.22)
            let spectralIndex = min(
                usableBins - 1,
                max(1, 1 + Int(abs(sin(spectralPhase)) * CGFloat(usableBins - 2)))
            )
            let spectrum = sqrt(CGFloat(max(0, magnitudes[spectralIndex])) / peak)
            let lowFlow = 0.5 + 0.5 * sin(angle * CGFloat(2 + (seed % 3)) + time * 0.74 + seedPhase * twoPi)
            let midFlow = 0.5 + 0.5 * sin(angle * CGFloat(4 + (seed / 5 % 4)) - time * 1.08)
            let lobeA = circularLobe(progress: progress, center: primaryCenter, width: 0.13 + audioLevel * 0.040)
            let lobeB = circularLobe(progress: progress, center: secondaryCenter, width: 0.17 + motionLevel * 0.034)
            let lobeC = circularLobe(progress: progress, center: shimmerCenter, width: 0.090 + audioLevel * 0.028)
            let base = 0.055 + audioLevel * 0.074
            let organic = (lowFlow * 0.105 + midFlow * 0.060) * (0.72 + audioLevel * 0.45)
            let spectralTexture = spectrum * (0.080 + audioLevel * 0.105)
            let movingPeaks = (lobeA * 0.46 + lobeB * 0.31 + lobeC * 0.19) * (0.65 + audioLevel * 0.38)
            let motionPulse = motionLevel * 0.18 * (0.64 + 0.36 * sin(angle * 3.0 + time * 1.05))

            return min(1.0, max(0.025, base + organic + spectralTexture + movingPeaks + motionPulse))
        }

        return smoothCircular(values, passes: 5)
    }

    private static func makeSignal(
        sampleCount: Int,
        playbackTime: Float,
        audioLevel: Float,
        motionIntensity: Float,
        trackSeed: Int
    ) -> [Float] {
        let seed = abs(trackSeed)
        let seedPhase = Float(seed % 10_000) / 10_000
        let tempo = Float(86 + (seed % 58))
        let beatHz = tempo / 60
        let beat = pow(max(0, sin(2 * .pi * beatHz * playbackTime)), 6)
        let accent = 0.52 + audioLevel * 0.52 + motionIntensity * 0.46 + beat * (0.20 + audioLevel * 0.28)

        let primary = Float(2 + (seed % 5))
        let secondary = Float(5 + (seed / 7 % 7))
        let shimmer = Float(11 + (seed / 19 % 11))

        return (0..<sampleCount).map { sampleIndex in
            let position = Float(sampleIndex) / Float(sampleCount)
            let phaseA = seedPhase + playbackTime * 0.075
            let phaseB = seedPhase * 0.37 + playbackTime * 0.135
            let phaseC = seedPhase * 0.19 + playbackTime * 0.245

            let low = sin(2 * .pi * (position * primary + phaseA))
            let mid = sin(2 * .pi * (position * secondary + phaseB))
            let high = sin(2 * .pi * (position * shimmer + phaseC))
            let headWobble = sin(2 * .pi * (position * (primary + 1.0) + playbackTime * (0.18 + motionIntensity * 0.38)))

            return (
                low * (0.48 + beat * 0.22)
                    + mid * (0.30 + audioLevel * 0.28)
                    + high * (0.12 + beat * 0.08 + audioLevel * 0.10)
                    + headWobble * motionIntensity * 0.42
            ) * accent
        }
    }

    private static func fftMagnitudes(_ signal: [Float]) -> [Float] {
        guard !signal.isEmpty else { return [] }

        var real = signal
        var imaginary = [Float](repeating: 0, count: signal.count)
        var magnitudes = [Float](repeating: 0, count: signal.count)
        let log2Count = vDSP_Length(log2(Double(signal.count)))

        guard signal.count == binCount, let setup = fftSetup else {
            return signal.map { abs($0) }
        }

        real.withUnsafeMutableBufferPointer { realBuffer in
            imaginary.withUnsafeMutableBufferPointer { imaginaryBuffer in
                guard let realPointer = realBuffer.baseAddress,
                      let imaginaryPointer = imaginaryBuffer.baseAddress else {
                    return
                }

                var splitComplex = DSPSplitComplex(realp: realPointer, imagp: imaginaryPointer)
                vDSP_fft_zip(setup, &splitComplex, 1, log2Count, FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(signal.count))
            }
        }

        return magnitudes
    }

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }

    private static func smoothCircular(_ values: [CGFloat], passes: Int) -> [CGFloat] {
        guard values.count > 2, passes > 0 else { return values }

        var smoothed = values
        for _ in 0..<passes {
            smoothed = smoothed.indices.map { index in
                let previous = smoothed[(index - 1 + smoothed.count) % smoothed.count]
                let current = smoothed[index]
                let next = smoothed[(index + 1) % smoothed.count]
                return previous * 0.24 + current * 0.52 + next * 0.24
            }
        }
        return smoothed
    }

    private static func circularLobe(progress: CGFloat, center: CGFloat, width: CGFloat) -> CGFloat {
        let distance = circularDistance(progress, center)
        let normalized = min(1.0, distance / max(0.001, width))
        let falloff = 1.0 - smoothstep(normalized)
        return falloff * falloff
    }

    private static func circularDistance(_ lhs: CGFloat, _ rhs: CGFloat) -> CGFloat {
        let distance = abs(lhs - rhs).truncatingRemainder(dividingBy: 1)
        return min(distance, 1 - distance)
    }

    private static func wrapUnit(_ value: CGFloat) -> CGFloat {
        let wrapped = value.truncatingRemainder(dividingBy: 1)
        return wrapped >= 0 ? wrapped : wrapped + 1
    }

    private static func smoothstep(_ value: CGFloat) -> CGFloat {
        let t = min(1.0, max(0.0, value))
        return t * t * (3.0 - 2.0 * t)
    }
}
