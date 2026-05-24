import Foundation

struct ExportResult: Identifiable {
    var id = UUID()
    var rawJSONURL: URL
    var trainingJSONLURL: URL
    var examplesCount: Int
    var exportedAt: Date
}

enum SessionExporter {
    static func export(_ collected: CollectedSession) throws -> ExportResult {
        let folder = try exportFolder()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let rawURL = folder.appendingPathComponent("\(collected.session.id)_raw.json")
        let rawData = try encoder.encode(collected)
        try rawData.write(to: rawURL, options: .atomic)

        let examples = FeatureExtractor.makeTrainingExamples(from: collected)
        let jsonlURL = folder.appendingPathComponent("\(collected.session.id)_training_examples.jsonl")
        let jsonlEncoder = JSONEncoder()
        jsonlEncoder.dateEncodingStrategy = .iso8601
        let jsonl = try examples
            .map { example in
                String(data: try jsonlEncoder.encode(example), encoding: .utf8) ?? ""
            }
            .joined(separator: "\n")
        try "\(jsonl)\n".write(to: jsonlURL, atomically: true, encoding: .utf8)

        return ExportResult(
            rawJSONURL: rawURL,
            trainingJSONLURL: jsonlURL,
            examplesCount: examples.count,
            exportedAt: Date()
        )
    }

    static func exportFolder() throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("HowTuneExports", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}

