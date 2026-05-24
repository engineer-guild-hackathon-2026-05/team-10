import AVFoundation
import Combine
import Foundation

@MainActor
final class DemoAudioPlayer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var errorMessage: String?

    private var engine: AVAudioEngine?
    private var player: AVAudioPlayerNode?

    func play(song: DemoSong) {
        stop()

        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            #endif

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
            let buffer = makeBuffer(song: song, format: format)

            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                Task { @MainActor in
                    self?.isPlaying = false
                }
            }
            player.play()

            self.engine = engine
            self.player = player
            isPlaying = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
        isPlaying = false
    }

    private func makeBuffer(song: DemoSong, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(song.durationSec * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        guard let channel = buffer.floatChannelData?[0] else {
            return buffer
        }

        let beatSec = 60.0 / song.bpm
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            var sample: Float = 0
            let beatPhase = t.truncatingRemainder(dividingBy: beatSec)
            let beatIndex = Int(t / beatSec)
            let intensity = song.pattern == .hype && t > 20 && t < 42 ? 1.35 : 1.0

            sample += tonePulse(
                t: t,
                phase: beatPhase,
                frequency: beatIndex.isMultiple(of: 4) ? 88 : 132,
                duration: 0.08,
                gain: 0.20 * intensity
            )

            if beatIndex % 4 == 2 {
                sample += tonePulse(
                    t: t,
                    phase: max(0, beatPhase - 0.02),
                    frequency: 220,
                    duration: 0.05,
                    gain: 0.10 * intensity
                )
            }

            if song.pattern != .chill {
                sample += tonePulse(
                    t: t,
                    phase: abs(beatPhase - beatSec / 2),
                    frequency: 420,
                    duration: 0.035,
                    gain: 0.055 * intensity
                )
            }

            if song.pattern == .chill {
                sample += Float(sin(2.0 * .pi * 176.0 * t)) * 0.025
            }

            channel[frame] = max(-0.7, min(0.7, sample))
        }

        return buffer
    }

    private func tonePulse(
        t: Double,
        phase: Double,
        frequency: Double,
        duration: Double,
        gain: Double
    ) -> Float {
        guard phase >= 0 && phase < duration else { return 0 }
        let envelope = exp(-phase * 28.0)
        return Float(sin(2.0 * .pi * frequency * t) * gain * envelope)
    }
}
