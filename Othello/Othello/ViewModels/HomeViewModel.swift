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
        if sensorStatus.headMotion == .disconnected {
            sensorStatus.headMotion = .disconnected
        }
    }

    func endSession() {
        isSessionActive = false
        sensorStatus = SensorStatusBundle(
            headMotion: sensorStatus.headMotion == .unsupported ? .unsupported : .disconnected
        )
    }
}
