import Foundation

#if os(iOS)
import CoreMotion

final class AirPodsMotionManager: NSObject, AirPodsMotionManaging {
    private let manager: CMHeadphoneMotionManager
    private let queue: OperationQueue
    private var playbackPositionProvider: PlaybackPositionProviding?

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
        self.playbackPositionProvider = playbackPositionProvider
        emitStatus(.starting)

        guard manager.isDeviceMotionAvailable else {
            emitStatus(.disconnected)
            emitEvent(.unavailable("対応AirPodsが接続されていないか、この端末では頭部モーションを取得できません。"))
            return
        }

        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                let status: AirPodsMotionStatus = self.manager.isDeviceMotionAvailable
                    ? .failed(error.localizedDescription)
                    : .disconnected
                self.emitStatus(status)
                self.emitEvent(.failed(error.localizedDescription))
                return
            }

            guard let motion else {
                self.emitStatus(.unavailable("頭部モーションのサンプルを取得できませんでした。"))
                return
            }

            self.emitStatus(.recording)
            self.onSample?(AirPodsMotionSample(
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
            ))
        }

        emitEvent(.started)
    }

    func stop() {
        guard manager.isDeviceMotionActive else {
            emitStatus(.stopped)
            return
        }

        manager.stopDeviceMotionUpdates()
        playbackPositionProvider = nil
        emitStatus(.stopped)
        emitEvent(.stopped)
    }

    private func emitStatus(_ status: AirPodsMotionStatus) {
        onStatusChange?(status)
    }

    private func emitEvent(_ kind: AirPodsMotionEvent.Kind) {
        onEvent?(AirPodsMotionEvent(occurredAt: Date(), kind: kind))
    }
}

extension AirPodsMotionManager: CMHeadphoneMotionManagerDelegate {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        emitStatus(.idle)
        emitEvent(.connected)
    }

    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        stop()
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
