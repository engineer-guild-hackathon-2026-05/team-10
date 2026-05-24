import CoreML
import Foundation

@MainActor
final class OthelloActivityClassifierService {
    private let model: MLModel?
    private var stateValues: [String: MLFeatureValue] = [:]

    init(bundle: Bundle = .main) {
        let compiledURL = bundle.url(forResource: "OthelloActivityClassifier", withExtension: "mlmodelc")
        let sourceURL = bundle.url(forResource: "OthelloActivityClassifier", withExtension: "mlmodel")

        let modelURL = compiledURL ?? sourceURL.flatMap { try? MLModel.compileModel(at: $0) }
        if let url = modelURL {
            self.model = try? MLModel(contentsOf: url)
        } else {
            self.model = nil
        }
    }

    var isAvailable: Bool {
        model != nil
    }

    func resetState() {
        stateValues.removeAll()
    }

    func predict(window: ReactionFeatureWindow) -> ActivityPrediction? {
        guard let model else { return nil }

        var values: [String: MLFeatureValue] = [:]
        for (name, description) in model.modelDescription.inputDescriptionsByName {
            if let value = featureValue(for: name, description: description, window: window) {
                values[name] = value
            } else if !description.isOptional {
                return nil
            }
        }

        guard let input = try? MLDictionaryFeatureProvider(dictionary: values),
              let output = try? model.prediction(from: input) else {
            return nil
        }

        updateState(from: output, model: model)
        return prediction(from: output)
    }

    private func featureValue(
        for name: String,
        description: MLFeatureDescription,
        window: ReactionFeatureWindow
    ) -> MLFeatureValue? {
        let normalizedName = name.normalizedCoreMLName

        if normalizedName.contains("statein") {
            if let existing = stateValues[name] {
                return existing
            }
            return zeroMultiArrayFeature(description: description)
        }

        switch description.type {
        case .double:
            return window.aggregateValue(for: name).map(MLFeatureValue.init(double:))
        case .int64:
            return window.aggregateValue(for: name).map { MLFeatureValue(int64: Int64($0.rounded())) }
        case .multiArray:
            if let feature = MotionFeature(modelInputName: name) {
                return multiArrayFeature(values: window.series(for: feature), description: description)
            }
            if normalizedName.contains("feature") || normalizedName.contains("input") {
                return featureMatrix(window: window, description: description)
            }
            return window.aggregateValue(for: name).flatMap {
                multiArrayFeature(values: [$0], description: description)
            }
        default:
            return nil
        }
    }

    private func zeroMultiArrayFeature(description: MLFeatureDescription) -> MLFeatureValue? {
        guard description.type == .multiArray else { return nil }

        let shape = sanitizedShape(description.multiArrayConstraint?.shape ?? [1])
        let dataType = description.multiArrayConstraint?.dataType ?? .double
        guard let array = try? MLMultiArray(shape: shape, dataType: dataType) else {
            return nil
        }

        for index in 0..<array.count {
            array[index] = 0
        }
        return MLFeatureValue(multiArray: array)
    }

    private func multiArrayFeature(
        values: [Double],
        description: MLFeatureDescription
    ) -> MLFeatureValue? {
        let shape = sanitizedShape(description.multiArrayConstraint?.shape ?? [NSNumber(value: max(values.count, 1))])
        let dataType = description.multiArrayConstraint?.dataType ?? .double
        guard let array = try? MLMultiArray(shape: shape, dataType: dataType) else {
            return nil
        }

        let paddedValues = values.paddedSuffix(count: array.count)
        for index in 0..<array.count {
            array[index] = NSNumber(value: paddedValues[index])
        }
        return MLFeatureValue(multiArray: array)
    }

    private func featureMatrix(
        window: ReactionFeatureWindow,
        description: MLFeatureDescription
    ) -> MLFeatureValue? {
        let shape = sanitizedShape(description.multiArrayConstraint?.shape ?? [NSNumber(value: 100), NSNumber(value: MotionFeature.allCases.count)])
        let dataType = description.multiArrayConstraint?.dataType ?? .double
        guard let array = try? MLMultiArray(shape: shape, dataType: dataType) else {
            return nil
        }

        let shapeInts = shape.map(\.intValue)
        let featureCount = MotionFeature.allCases.count
        let sampleCount = max(1, array.count / featureCount)
        let series = MotionFeature.allCases.map { feature in
            window.series(for: feature).paddedSuffix(count: sampleCount)
        }

        for index in 0..<array.count {
            array[index] = 0
        }

        if shapeInts.last == featureCount {
            for timeIndex in 0..<sampleCount {
                for featureIndex in 0..<featureCount {
                    let flatIndex = (timeIndex * featureCount) + featureIndex
                    guard flatIndex < array.count else { continue }
                    array[flatIndex] = NSNumber(value: series[featureIndex][timeIndex])
                }
            }
        } else {
            for featureIndex in 0..<featureCount {
                for timeIndex in 0..<sampleCount {
                    let flatIndex = (featureIndex * sampleCount) + timeIndex
                    guard flatIndex < array.count else { continue }
                    array[flatIndex] = NSNumber(value: series[featureIndex][timeIndex])
                }
            }
        }

        return MLFeatureValue(multiArray: array)
    }

    private func sanitizedShape(_ shape: [NSNumber]) -> [NSNumber] {
        shape.map { NSNumber(value: max(1, $0.intValue)) }
    }

    private func updateState(from output: MLFeatureProvider, model: MLModel) {
        let stateInputNames = model.modelDescription.inputDescriptionsByName.keys
            .filter { $0.normalizedCoreMLName.contains("statein") }

        guard !stateInputNames.isEmpty else { return }

        for outputName in output.featureNames where outputName.normalizedCoreMLName.contains("stateout") {
            guard let value = output.featureValue(for: outputName), value.type == .multiArray else {
                continue
            }

            if let exactInputName = stateInputNames.first(where: {
                outputName.replacingOccurrences(of: "Out", with: "In") == $0
            }) {
                stateValues[exactInputName] = value
            } else if let firstInputName = stateInputNames.first {
                stateValues[firstInputName] = value
            }
        }
    }

    private func prediction(from output: MLFeatureProvider) -> ActivityPrediction {
        var label: String?
        var probabilities: [String: Double] = [:]

        for name in output.featureNames {
            guard let value = output.featureValue(for: name) else { continue }
            let normalizedName = name.normalizedCoreMLName

            if value.type == .string, normalizedName.contains("label"), !normalizedName.contains("prob") {
                label = value.stringValue
            } else if value.type == .dictionary {
                for (key, probability) in value.dictionaryValue {
                    probabilities[String(describing: key)] = probability.doubleValue
                }
            }
        }

        return ActivityPrediction(label: label, probabilities: probabilities)
    }
}

extension Array where Element == Double {
    fileprivate func paddedSuffix(count: Int) -> [Double] {
        guard count > 0 else { return [] }

        let suffixValues = self.count > count ? Array(suffix(count)) : self
        if suffixValues.count == count {
            return suffixValues
        }

        return Array(repeating: 0, count: count - suffixValues.count) + suffixValues
    }
}

extension String {
    fileprivate var normalizedCoreMLName: String {
        lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
