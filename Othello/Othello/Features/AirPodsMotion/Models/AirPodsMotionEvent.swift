import Foundation

struct AirPodsMotionEvent: Identifiable, Equatable {
    let id = UUID()
    let occurredAt: Date
    let kind: Kind

    enum Kind: Equatable {
        case started
        case stopped
        case connected
        case disconnected
        case unavailable(String)
        case failed(String)
    }

    var message: String {
        switch kind {
        case .started:
            return "AirPods motion recording started."
        case .stopped:
            return "AirPods motion recording stopped."
        case .connected:
            return "AirPods motion became available."
        case .disconnected:
            return "AirPods disconnected. Fallback is required."
        case .unavailable(let reason):
            return "AirPods motion unavailable: \(reason)"
        case .failed(let reason):
            return "AirPods motion failed: \(reason)"
        }
    }
}
