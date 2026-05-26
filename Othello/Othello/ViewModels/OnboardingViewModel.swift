import Combine
import CoreMotion
import Foundation
import MusicKit

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var permissionState = PermissionState()
    @Published var currentPage: Int = 0
    @Published var isOnboardingComplete: Bool = false
    @Published var useManualMode: Bool = false
    @Published var appleMusicAccessStatus: AppleMusicAccessStatus = .init(
        authorizationStatus: MusicAuthorization.currentStatus
    )

    private let headphoneMotionManager = CMHeadphoneMotionManager()

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["HOWTUNE_SKIP_ONBOARDING"] == "1" {
            isOnboardingComplete = true
            useManualMode = true
        }
        #endif
        checkAirPodsAvailability()
        if MusicAuthorization.currentStatus == .authorized {
            Task { await refreshAppleMusicSubscriptionStatus() }
        }
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

    func requestAppleMusicPermission() async {
        appleMusicAccessStatus = .checking
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            appleMusicAccessStatus = AppleMusicAccessStatus(authorizationStatus: status)
            return
        }

        await refreshAppleMusicSubscriptionStatus()
    }

    func refreshAppleMusicSubscriptionStatus() async {
        guard MusicAuthorization.currentStatus == .authorized else {
            appleMusicAccessStatus = AppleMusicAccessStatus(authorizationStatus: MusicAuthorization.currentStatus)
            return
        }

        appleMusicAccessStatus = .checking

        do {
            let subscription = try await MusicSubscription.current
            appleMusicAccessStatus = subscription.canPlayCatalogContent ? .authorized : .subscriptionRequired
        } catch {
            appleMusicAccessStatus = .unavailable
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
