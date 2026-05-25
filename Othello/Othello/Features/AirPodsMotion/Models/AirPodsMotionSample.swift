import Foundation

struct AirPodsMotionSample: Identifiable, Equatable {
    let id = UUID()
    let capturedAt: Date
    let playbackTime: TimeInterval?
    let userAcceleration: MotionVector
    let rotationRate: MotionVector
    let attitude: HeadAttitude

    var accelerationMagnitude: Double {
        userAcceleration.magnitude
    }

    var rotationMagnitude: Double {
        rotationRate.magnitude
    }

    var interactionIntensity: Double {
        let accelerationScore = min(1.0, accelerationMagnitude * 1.8)
        let rotationScore = min(1.0, rotationMagnitude / 6.5)
        return min(1.0, accelerationScore * 0.58 + rotationScore * 0.42)
    }
}

struct MotionVector: Equatable {
    let x: Double
    let y: Double
    let z: Double

    var magnitude: Double {
        sqrt((x * x) + (y * y) + (z * z))
    }
}

struct HeadAttitude: Equatable {
    let pitch: Double
    let roll: Double
    let yaw: Double
}
