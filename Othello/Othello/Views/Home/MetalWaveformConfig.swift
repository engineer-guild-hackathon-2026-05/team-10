import Foundation

#if os(iOS)
struct MetalWaveformConfig {
    var isAnimating: Bool = false
    var playbackTime: TimeInterval = 0
    var audioLevel: Double = 0
    var motionIntensity: Double = 0
    var trackSeed: Int = 0
    var reactionState: HowTag = .neutral
}
#endif
