import Foundation
import Combine

@MainActor
final class AirPodsMotionViewModel: ObservableObject {
    @Published private(set) var status: AirPodsMotionStatus = .idle
    @Published private(set) var latestSample: AirPodsMotionSample?
    @Published private(set) var samples: [AirPodsMotionSample] = []
    @Published private(set) var events: [AirPodsMotionEvent] = []

    private let manager: AirPodsMotionManaging
    private let maxStoredSamples: Int

    init(
        manager: AirPodsMotionManaging? = nil,
        maxStoredSamples: Int = 300
    ) {
        let manager = manager ?? AirPodsMotionManager()
        self.manager = manager
        self.maxStoredSamples = maxStoredSamples

        manager.onStatusChange = { [weak self] status in
            Task { @MainActor in
                guard let self, self.status != status else { return }
                self.status = status
            }
        }

        manager.onSample = { [weak self] sample in
            Task { @MainActor in
                self?.append(sample)
            }
        }

        manager.onEvent = { [weak self] event in
            Task { @MainActor in
                self?.events.insert(event, at: 0)
            }
        }
    }

    var isRecording: Bool {
        status.isRecording
    }

    var fallbackRequired: Bool {
        switch status {
        case .disconnected, .unsupported, .unavailable, .failed:
            return true
        default:
            return false
        }
    }

    var recentInteractionIntensity: Double {
        samples.suffix(18).map(\.interactionIntensity).max() ?? latestSample?.interactionIntensity ?? 0
    }

    func start(playbackPositionProvider: PlaybackPositionProviding? = nil) {
        samples.removeAll()
        latestSample = nil
        let provider = playbackPositionProvider ?? SessionElapsedPlaybackPositionProvider(startedAt: Date())
        manager.start(playbackPositionProvider: provider)
    }

    func stop() {
        manager.stop()
    }

    private func append(_ sample: AirPodsMotionSample) {
        latestSample = sample
        samples.append(sample)

        if samples.count > maxStoredSamples {
            samples.removeFirst(samples.count - maxStoredSamples)
        }
    }
}
