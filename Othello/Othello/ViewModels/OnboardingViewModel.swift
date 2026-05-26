import Combine
import CoreMotion
import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var permissionState = PermissionState()
    @Published var currentPage: Int = 0
    @Published var isOnboardingComplete: Bool = false
    @Published var useManualMode: Bool = false

    private let headphoneMotionManager = CMHeadphoneMotionManager()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["HOWTUNE_SKIP_ONBOARDING"] == "1" {
            isOnboardingComplete = true
            useManualMode = true
        }
        #endif
        checkAirPodsAvailability()
    }

    func checkAirPodsAvailability() {
        permissionState.airPodsAvailable = headphoneMotionManager.isDeviceMotionAvailable
    }

    func requestMotionPermission() async {
        #if os(iOS)
        checkAirPodsAvailability()
        permissionState.motion = permissionState.airPodsAvailable ? .authorized : .denied
        #else
        permissionState.motion = .denied
        #endif
    }

    func proceedToManualMode() {
        useManualMode = true
        isOnboardingComplete = true
    }

    func completeOnboarding() {
        isOnboardingComplete = true
    }
}
