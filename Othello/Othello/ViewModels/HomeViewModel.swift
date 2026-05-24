import Combine
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isSessionActive: Bool = false
    @Published var isPlaying: Bool = false
    @Published var playbackTime: TimeInterval = 0
    @Published var sensorStatus: SensorStatusBundle
    @Published var useManualMode: Bool

    let mockTrackTitle: String = "感電"
    let mockTrackArtist: String = "米津玄師"
    let mockTrackDuration: TimeInterval = 268

    private var timerCancellable: AnyCancellable?

    init(useManualMode: Bool, permissionState: PermissionState) {
        self.useManualMode = useManualMode
        self.sensorStatus = SensorStatusBundle.from(permissionState)
    }

    func startSession() {
        isSessionActive = true
        if sensorStatus.headMotion == .disconnected {
            sensorStatus.headMotion = .disconnected
        }
        if sensorStatus.heartRate == .stopped {
            sensorStatus.heartRate = .acquiring
        }
    }

    func endSession() {
        isSessionActive = false
        isPlaying = false
        stopTimer()
        sensorStatus = SensorStatusBundle(
            headMotion: sensorStatus.headMotion == .unsupported ? .unsupported : .disconnected,
            bodyMotion: sensorStatus.bodyMotion == .unauthorized || sensorStatus.bodyMotion == .unsupported
                ? sensorStatus.bodyMotion : .stopped,
            heartRate: sensorStatus.heartRate == .unauthorized || sensorStatus.heartRate == .unsupported
                ? sensorStatus.heartRate : .stopped
        )
    }

    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            startTimer()
        } else {
            stopTimer()
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.playbackTime < self.mockTrackDuration {
                    self.playbackTime += 0.1
                } else {
                    self.isPlaying = false
                    self.stopTimer()
                }
            }
    }

    func updateHeadMotionStatus(from status: AirPodsMotionStatus) {
        switch status {
        case .recording:
            sensorStatus.headMotion = .connected
        case .unsupported:
            sensorStatus.headMotion = .unsupported
        case .idle, .starting, .stopped, .disconnected, .unavailable, .failed:
            sensorStatus.headMotion = .disconnected
        }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
