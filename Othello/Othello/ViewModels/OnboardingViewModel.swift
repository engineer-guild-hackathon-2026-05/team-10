import Combine
import CoreMotion
import Foundation
import HealthKit

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var permissionState = PermissionState()
    @Published var currentPage: Int = 0
    @Published var isOnboardingComplete: Bool = false
    @Published var useManualMode: Bool = false

    private let headphoneMotionManager = CMHeadphoneMotionManager()
    private let healthStore = HKHealthStore()

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
        guard CMMotionActivityManager.isActivityAvailable() else {
            permissionState.motion = .denied
            return
        }
        let manager = CMMotionActivityManager()
        await withCheckedContinuation { continuation in
            manager.queryActivityStarting(
                from: Date(),
                to: Date(),
                to: .main
            ) { [weak self] _, error in
                if error != nil {
                    self?.permissionState.motion = .denied
                } else {
                    self?.permissionState.motion = .authorized
                }
                continuation.resume()
            }
        }
        #else
        permissionState.motion = .denied
        #endif
    }

    func requestHealthPermission() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            permissionState.health = .denied
            return
        }
        let heartRateType = HKQuantityType(.heartRate)
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [heartRateType])
            let status = healthStore.authorizationStatus(for: heartRateType)
            permissionState.health = status == .sharingAuthorized ? .authorized : .denied
        } catch {
            permissionState.health = .denied
        }
    }

    func proceedToManualMode() {
        useManualMode = true
        isOnboardingComplete = true
    }

    func completeOnboarding() {
        isOnboardingComplete = true
    }
}
