import Foundation

#if os(iOS)
import CoreMotion

final class AirPodsMotionManager: NSObject, AirPodsMotionManaging {
    private let manager: CMHeadphoneMotionManager
    private let queue: OperationQueue
    private var playbackPositionProvider: PlaybackPositionProviding?
    private var isCaptureRequested = false
    private var sampleCount = 0
    private var lastDebugSampleLoggedAt: TimeInterval = 0

    var onEvent: ((AirPodsMotionEvent) -> Void)?
    var onSample: ((AirPodsMotionSample) -> Void)?
    var onStatusChange: ((AirPodsMotionStatus) -> Void)?

    var isDeviceMotionAvailable: Bool {
        manager.isDeviceMotionAvailable
    }

    override init() {
        self.manager = CMHeadphoneMotionManager()
        self.queue = OperationQueue()
        self.queue.name = "AirPodsMotionManager.queue"
        self.queue.qualityOfService = .userInitiated
        super.init()
        manager.delegate = self
    }

    func start(playbackPositionProvider: PlaybackPositionProviding) {
        guard !isCaptureRequested else {
            debugLog("start ignored because capture is already requested active=\(manager.isDeviceMotionActive)")
            return
        }

        isCaptureRequested = true
        sampleCount = 0
        self.playbackPositionProvider = playbackPositionProvider
        emitStatus(.starting)
        debugLog(
            "start requested connectionStatusActive=\(manager.isConnectionStatusActive) "
                + "deviceMotionAvailable=\(manager.isDeviceMotionAvailable)"
        )

        if !manager.isConnectionStatusActive {
            manager.startConnectionStatusUpdates()
            debugLog("connection status updates started")
        }

        guard manager.isDeviceMotionAvailable else {
            isCaptureRequested = false
            debugLog("device motion unavailable")
            emitStatus(.disconnected)
            emitEvent(.unavailable("対応AirPodsが接続されていないか、この端末では頭部モーションを取得できません。"))
            return
        }

        startDeviceMotionUpdatesIfNeeded()
        emitEvent(.started)
    }

    func stop() {
        let wasDeviceMotionActive = manager.isDeviceMotionActive
        isCaptureRequested = false
        if wasDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
            debugLog("device motion updates stopped")
        }

        if manager.isConnectionStatusActive {
            manager.stopConnectionStatusUpdates()
            debugLog("connection status updates stopped")
        }

        playbackPositionProvider = nil
        emitStatus(.stopped)
        if wasDeviceMotionActive {
            emitEvent(.stopped)
        }
    }

    private func startDeviceMotionUpdatesIfNeeded() {
        guard isCaptureRequested else {
            debugLog("device motion updates skipped because capture is not requested")
            return
        }

        guard manager.isDeviceMotionAvailable else {
            debugLog("device motion updates skipped because device motion is unavailable")
            emitStatus(.disconnected)
            emitEvent(.unavailable("対応AirPodsが接続されていないか、この端末では頭部モーションを取得できません。"))
            return
        }

        guard !manager.isDeviceMotionActive else {
            debugLog("device motion updates already active")
            return
        }

        debugLog("device motion updates starting")
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                let status: AirPodsMotionStatus = self.manager.isDeviceMotionAvailable
                    ? .failed(error.localizedDescription)
                    : .disconnected
                self.debugLog("device motion error=\(error.localizedDescription)")
                self.emitStatus(status)
                self.emitEvent(.failed(error.localizedDescription))
                return
            }

            guard let motion else {
                self.debugLog("device motion callback returned nil sample")
                self.emitStatus(.unavailable("頭部モーションのサンプルを取得できませんでした。"))
                return
            }

            self.emitStatus(.recording)
            let sample = AirPodsMotionSample(
                capturedAt: Date(),
                playbackTime: self.playbackPositionProvider?.currentPlaybackTime(),
                userAcceleration: MotionVector(
                    x: motion.userAcceleration.x,
                    y: motion.userAcceleration.y,
                    z: motion.userAcceleration.z
                ),
                rotationRate: MotionVector(
                    x: motion.rotationRate.x,
                    y: motion.rotationRate.y,
                    z: motion.rotationRate.z
                ),
                attitude: HeadAttitude(
                    pitch: motion.attitude.pitch,
                    roll: motion.attitude.roll,
                    yaw: motion.attitude.yaw
                )
            )
            self.sampleCount += 1
            self.debugLogSample(sample)
            self.onSample?(sample)
        }

        debugLog("device motion updates requested active=\(manager.isDeviceMotionActive)")
        scheduleDebugSampleWatchdog()
    }

    private func emitStatus(_ status: AirPodsMotionStatus) {
        onStatusChange?(status)
    }

    private func emitEvent(_ kind: AirPodsMotionEvent.Kind) {
        onEvent?(AirPodsMotionEvent(occurredAt: Date(), kind: kind))
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[AirPodsMotion] \(message)")
        #endif
    }

    private func debugLogSample(_ sample: AirPodsMotionSample) {
        #if DEBUG
        let now = Date().timeIntervalSince1970
        guard now - lastDebugSampleLoggedAt >= 0.5 else { return }
        lastDebugSampleLoggedAt = now

        let playbackText = sample.playbackTime.map { String(format: "%.2f", $0) } ?? "nil"
        print(String(
            format: "[AirPodsMotion] sample intensity=%.3f acc=%.3f rot=%.3f "
                + "acc=(%.3f, %.3f, %.3f) rot=(%.3f, %.3f, %.3f) playback=%@",
            sample.interactionIntensity,
            sample.accelerationMagnitude,
            sample.rotationMagnitude,
            sample.userAcceleration.x,
            sample.userAcceleration.y,
            sample.userAcceleration.z,
            sample.rotationRate.x,
            sample.rotationRate.y,
            sample.rotationRate.z,
            playbackText
        ))
        #endif
    }

    private func scheduleDebugSampleWatchdog() {
        #if DEBUG
        let observedSampleCount = sampleCount
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self,
                  self.isCaptureRequested,
                  self.sampleCount == observedSampleCount else {
                return
            }

            self.debugLog(
                "no samples after 2s active=\(self.manager.isDeviceMotionActive) "
                    + "deviceMotionAvailable=\(self.manager.isDeviceMotionAvailable) "
                    + "connectionStatusActive=\(self.manager.isConnectionStatusActive)"
            )
        }
        #endif
    }
}

extension AirPodsMotionManager: CMHeadphoneMotionManagerDelegate {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        debugLog(
            "headphone motion connected captureRequested=\(isCaptureRequested) "
                + "active=\(manager.isDeviceMotionActive)"
        )
        emitStatus(isCaptureRequested ? .starting : .idle)
        emitEvent(.connected)
        startDeviceMotionUpdatesIfNeeded()
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        debugLog(
            "headphone motion disconnected captureRequested=\(isCaptureRequested) "
                + "active=\(manager.isDeviceMotionActive)"
        )
        emitStatus(.disconnected)
        emitEvent(.disconnected)
    }
}
#else
final class AirPodsMotionManager: AirPodsMotionManaging {
    var onEvent: ((AirPodsMotionEvent) -> Void)?
    var onSample: ((AirPodsMotionSample) -> Void)?
    var onStatusChange: ((AirPodsMotionStatus) -> Void)?

    var isDeviceMotionAvailable: Bool {
        false
    }

    func start(playbackPositionProvider: PlaybackPositionProviding) {
        onStatusChange?(.unsupported)
        onEvent?(AirPodsMotionEvent(
            occurredAt: Date(),
            kind: .unavailable("AirPods頭部モーションはiOSでのみ利用できます。")
        ))
    }

    func stop() {
        onStatusChange?(.stopped)
    }
}
#endif
