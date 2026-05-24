import Foundation

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
}

struct PermissionState {
    var motion: PermissionStatus = .notDetermined
    var health: PermissionStatus = .notDetermined
    var airPodsAvailable: Bool = false
}
