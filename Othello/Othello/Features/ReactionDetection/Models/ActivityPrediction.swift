import Foundation

struct ActivityPrediction: Equatable {
    let label: String?
    let probabilities: [String: Double]

    var displayLabel: String? {
        label ?? probabilities.max(by: { $0.value < $1.value })?.key
    }
}
