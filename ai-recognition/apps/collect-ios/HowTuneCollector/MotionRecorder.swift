import Combine
import CoreMotion
import Foundation

@MainActor
final class MotionRecorder: ObservableObject {
    @Published private(set) var samples: [MotionSample] = []
    @Published private(set) var currentMagnitude: Double = 0
    @Published private(set) var statusText = "待機中"

    #if os(iOS)
    private let manager = CMMotionManager()
    private let queue = OperationQueue()
    #endif
    private var sessionStartedAt: Date?
    private let gravity = 9.80665

    var sampleCount: Int { samples.count }

    func start(sessionStartedAt: Date) {
        stop()
        samples.removeAll(keepingCapacity: true)
        currentMagnitude = 0
        self.sessionStartedAt = sessionStartedAt
        #if os(iOS)
        queue.qualityOfService = .userInitiated

        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 1.0 / 30.0
            manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
                guard let self, let motion else { return }
                let acceleration = motion.userAcceleration
                let gravityVector = motion.gravity
                let ax = (acceleration.x + gravityVector.x) * self.gravity
                let ay = (acceleration.y + gravityVector.y) * self.gravity
                let az = (acceleration.z + gravityVector.z) * self.gravity
                let rotation = motion.rotationRate

                Task { @MainActor in
                    self.appendSample(ax: ax, ay: ay, az: az, gx: rotation.x, gy: rotation.y, gz: rotation.z)
                }
            }
            statusText = "DeviceMotion取得中"
        } else if manager.isAccelerometerAvailable {
            manager.accelerometerUpdateInterval = 1.0 / 30.0
            manager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                guard let self, let data else { return }
                let acceleration = data.acceleration

                Task { @MainActor in
                    self.appendSample(
                        ax: acceleration.x * self.gravity,
                        ay: acceleration.y * self.gravity,
                        az: acceleration.z * self.gravity,
                        gx: nil,
                        gy: nil,
                        gz: nil
                    )
                }
            }
            statusText = "Accelerometer取得中"
        } else {
            statusText = "センサー未対応"
        }
        #else
        statusText = "iPhone実機でセンサー取得"
        #endif
    }

    func stop() {
        #if os(iOS)
        manager.stopDeviceMotionUpdates()
        manager.stopAccelerometerUpdates()
        #endif
        sessionStartedAt = nil
        if statusText != "センサー未対応" {
            statusText = "停止中"
        }
    }

    func reset() {
        stop()
        samples.removeAll()
        currentMagnitude = 0
        statusText = "待機中"
    }

    private func appendSample(ax: Double, ay: Double, az: Double, gx: Double?, gy: Double?, gz: Double?) {
        guard let sessionStartedAt else { return }
        let elapsed = Date().timeIntervalSince(sessionStartedAt)
        currentMagnitude = sqrt(ax * ax + ay * ay + az * az)
        samples.append(
            MotionSample(
                t: rounded(elapsed),
                ax: ax,
                ay: ay,
                az: az,
                gx: gx,
                gy: gy,
                gz: gz
            )
        )
    }

    private func rounded(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }
}
