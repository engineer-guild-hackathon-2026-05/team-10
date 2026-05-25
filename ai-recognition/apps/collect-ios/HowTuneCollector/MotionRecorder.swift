import Combine
import CoreMotion
import Foundation

@MainActor
final class MotionRecorder: ObservableObject {
    @Published private(set) var samples: [MotionSample] = []
    @Published private(set) var currentMagnitude: Double = 0
    @Published private(set) var statusText = "待機中"

    #if os(iOS)
    private let headphoneMotionManager = CMHeadphoneMotionManager()
    private let deviceMotionManager = CMMotionManager()
    private let queue = OperationQueue()
    #endif
    private var sessionStartedAt: Date?
    private var isUsingDeviceFallback = false

    var sampleCount: Int { samples.count }

    func start(sessionStartedAt: Date) {
        stop()
        samples.removeAll(keepingCapacity: true)
        currentMagnitude = 0
        self.sessionStartedAt = sessionStartedAt
        #if os(iOS)
        queue.name = "HowTune.MotionRecorder"
        queue.qualityOfService = .userInitiated

        if !startHeadphoneMotionUpdates() {
            startDeviceMotionFallback(reason: "AirPods未接続")
        }
        #else
        statusText = "iPhone実機とAirPodsでセンサー取得"
        #endif
    }

    func stop() {
        #if os(iOS)
        headphoneMotionManager.stopDeviceMotionUpdates()
        deviceMotionManager.stopDeviceMotionUpdates()
        deviceMotionManager.stopAccelerometerUpdates()
        isUsingDeviceFallback = false
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

    private struct MotionValues {
        var ax: Double
        var ay: Double
        var az: Double
        var gx: Double?
        var gy: Double?
        var gz: Double?
        var source: MotionSensorSource
        var pitch: Double?
        var roll: Double?
        var yaw: Double?
    }

    #if os(iOS)
    private func startHeadphoneMotionUpdates() -> Bool {
        guard headphoneMotionManager.isDeviceMotionAvailable else {
            return false
        }

        headphoneMotionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, error in
            guard let self else { return }
            if error != nil {
                Task { @MainActor in
                    self.startDeviceMotionFallback(reason: "AirPods取得エラー")
                }
                return
            }

            guard let motion else {
                Task { @MainActor in
                    self.startDeviceMotionFallback(reason: "AirPods切断")
                }
                return
            }

            let values = Self.motionValues(from: motion, source: .headphoneMotion)
            Task { @MainActor in
                self.appendSample(values)
            }
        }
        statusText = "AirPods頭部モーション取得中"
        return true
    }

    private func startDeviceMotionFallback(reason: String) {
        guard !isUsingDeviceFallback else { return }
        headphoneMotionManager.stopDeviceMotionUpdates()
        deviceMotionManager.stopDeviceMotionUpdates()
        deviceMotionManager.stopAccelerometerUpdates()
        isUsingDeviceFallback = true

        if deviceMotionManager.isDeviceMotionAvailable {
            deviceMotionManager.deviceMotionUpdateInterval = 1.0 / 30.0
            deviceMotionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
                guard let self, let motion else { return }
                let values = Self.motionValues(from: motion, source: .deviceMotion)

                Task { @MainActor in
                    self.appendSample(values)
                }
            }
            statusText = "\(reason): iPhoneモーション取得中"
        } else if deviceMotionManager.isAccelerometerAvailable {
            deviceMotionManager.accelerometerUpdateInterval = 1.0 / 30.0
            deviceMotionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
                guard let self, let data else { return }
                let values = Self.accelerometerValues(from: data)

                Task { @MainActor in
                    self.appendSample(values)
                }
            }
            statusText = "\(reason): iPhone加速度取得中"
        } else {
            statusText = "センサー未対応"
        }
    }

    private nonisolated static func motionValues(from motion: CMDeviceMotion, source: MotionSensorSource) -> MotionValues {
        let gravity = 9.80665
        let acceleration = motion.userAcceleration
        let gravityVector = motion.gravity
        let rotation = motion.rotationRate
        let attitude = motion.attitude

        return MotionValues(
            ax: (acceleration.x + gravityVector.x) * gravity,
            ay: (acceleration.y + gravityVector.y) * gravity,
            az: (acceleration.z + gravityVector.z) * gravity,
            gx: rotation.x,
            gy: rotation.y,
            gz: rotation.z,
            source: source,
            pitch: attitude.pitch,
            roll: attitude.roll,
            yaw: attitude.yaw
        )
    }

    private nonisolated static func accelerometerValues(from data: CMAccelerometerData) -> MotionValues {
        let gravity = 9.80665
        let acceleration = data.acceleration

        return MotionValues(
            ax: acceleration.x * gravity,
            ay: acceleration.y * gravity,
            az: acceleration.z * gravity,
            gx: nil,
            gy: nil,
            gz: nil,
            source: .accelerometer,
            pitch: nil,
            roll: nil,
            yaw: nil
        )
    }
    #endif

    private func appendSample(_ values: MotionValues) {
        guard let sessionStartedAt else { return }
        let elapsed = Date().timeIntervalSince(sessionStartedAt)
        currentMagnitude = sqrt(values.ax * values.ax + values.ay * values.ay + values.az * values.az)
        samples.append(
            MotionSample(
                t: rounded(elapsed),
                ax: values.ax,
                ay: values.ay,
                az: values.az,
                gx: values.gx,
                gy: values.gy,
                gz: values.gz,
                source: values.source,
                pitch: values.pitch,
                roll: values.roll,
                yaw: values.yaw
            )
        )
    }

    private func rounded(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }
}
