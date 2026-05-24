import Combine
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isSessionActive: Bool = false
    @Published var sensorStatus: SensorStatusBundle
    @Published var useManualMode: Bool

    init(useManualMode: Bool, permissionState: PermissionState) {
        self.useManualMode = useManualMode
        self.sensorStatus = SensorStatusBundle.from(permissionState)
    }

    func startSession() {
        isSessionActive = true
        // セッション開始時にセンサー状態を「取得中」へ更新
        if sensorStatus.headMotion == .disconnected {
            sensorStatus.headMotion = .disconnected // AirPods は接続状態による
        }
        if sensorStatus.bodyMotion == .stopped {
            sensorStatus.bodyMotion = .acquiring
        }
        if sensorStatus.heartRate == .stopped {
            sensorStatus.heartRate = .acquiring
        }
    }

    func endSession() {
        isSessionActive = false
        sensorStatus = SensorStatusBundle(
            headMotion: sensorStatus.headMotion == .unsupported ? .unsupported : .disconnected,
            bodyMotion: sensorStatus.bodyMotion == .unauthorized || sensorStatus.bodyMotion == .unsupported
                ? sensorStatus.bodyMotion : .stopped,
            heartRate: sensorStatus.heartRate == .unauthorized || sensorStatus.heartRate == .unsupported
                ? sensorStatus.heartRate : .stopped
        )
    }
}
