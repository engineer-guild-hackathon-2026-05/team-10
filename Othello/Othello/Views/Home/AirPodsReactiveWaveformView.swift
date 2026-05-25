import SwiftUI

#if os(iOS)
import MetalKit

struct AirPodsReactiveWaveformView: UIViewRepresentable {
    let isAnimating: Bool
    let playbackTime: TimeInterval
    let audioLevel: Double
    let motionIntensity: Double
    let trackSeed: Int
    let reactionState: HowTag

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.isOpaque = false
        view.backgroundColor = .clear
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.preferredFramesPerSecond = 30
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        context.coordinator.renderer.attach(to: view)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        view.preferredFramesPerSecond = isAnimating ? 30 : 10
        context.coordinator.renderer.update(
            MetalWaveformConfig(
                isAnimating: isAnimating,
                playbackTime: playbackTime,
                audioLevel: audioLevel,
                motionIntensity: motionIntensity,
                trackSeed: trackSeed,
                reactionState: reactionState
            )
        )
    }

    final class Coordinator {
        let renderer = MetalWaveformRenderer()
    }
}

#else
struct AirPodsReactiveWaveformView: View {
    let isAnimating: Bool
    let playbackTime: TimeInterval
    let audioLevel: Double
    let motionIntensity: Double
    let trackSeed: Int
    let reactionState: HowTag

    var body: some View {
        Circle()
            .stroke(Color.white.opacity(isAnimating ? 0.24 : 0.08), lineWidth: 3)
    }
}
#endif
