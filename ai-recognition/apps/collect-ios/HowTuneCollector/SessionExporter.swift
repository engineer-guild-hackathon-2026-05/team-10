import Foundation

struct ExportResult: Identifiable {
    var id = UUID()
    var rawJSONURL: URL
    var trainingJSONLURL: URL
    var recordingCSVURL: URL
    var annotationsCSVURL: URL
    var createMLActivityDataURL: URL
    var activityCSVCount: Int
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

        let recordingCSVURL = folder.appendingPathComponent("\(collected.session.id)_recording.csv")
        try makeRecordingCSV(from: collected.samples).write(to: recordingCSVURL, atomically: true, encoding: .utf8)

        let annotationsCSVURL = folder.appendingPathComponent("annotations.csv")
        try updateAnnotationsCSV(
            at: annotationsCSVURL,
            recordingFileName: recordingCSVURL.lastPathComponent,
            rows: makeAnnotationRows(from: collected)
        )

        let createMLActivityDataURL = folder.appendingPathComponent("CreateMLActivityData", isDirectory: true)
        let activityCSVCount = try writeLabeledActivityCSVs(from: collected, to: createMLActivityDataURL)

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
            recordingCSVURL: recordingCSVURL,
            annotationsCSVURL: annotationsCSVURL,
            createMLActivityDataURL: createMLActivityDataURL,
            activityCSVCount: activityCSVCount,
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

    private struct AnnotationRow {
        var label: ListeningLabel
        var start: TimeInterval
        var end: TimeInterval
        var motionSource: MotionSensorSource
    }

    private static let annotationHeader = "recording,label,start,end,motionSource"
    private static let labelPriority: [ListeningLabel] = [.hit, .hype, .groove, .chill, .immersion, .afterglow]

    private static func makeRecordingCSV(from samples: [MotionSample]) -> String {
        let header = "t,ax,ay,az,gx,gy,gz,pitch,roll,yaw"
        let lines = samples.sorted { $0.t < $1.t }.map { sample in
            [
                format(sample.t),
                format(sample.ax),
                format(sample.ay),
                format(sample.az),
                format(sample.gx ?? 0),
                format(sample.gy ?? 0),
                format(sample.gz ?? 0),
                format(sample.pitch ?? 0),
                format(sample.roll ?? 0),
                format(sample.yaw ?? 0)
            ].joined(separator: ",")
        }

        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    private static func makeAnnotationRows(from collected: CollectedSession) -> [AnnotationRow] {
        let source = dominantMotionSource(collected.samples)
        let labels = collected.labels
            .filter { $0.label.trainingLabel }
            .filter { $0.endedAtSec > $0.startedAtSec }
        guard !labels.isEmpty else { return [] }

        let noiseLabels = collected.labels.filter { $0.label == .noise }
        let boundaries = Set(labels.flatMap { [$0.startedAtSec, $0.endedAtSec] }).sorted()

        return zip(boundaries, boundaries.dropFirst()).compactMap { start, end in
            guard end > start else { return nil }
            guard !hasNoiseOverlap(start: start, end: end, noiseLabels: noiseLabels) else { return nil }

            let activeLabels = labels
                .filter { overlap(start, end, $0.startedAtSec, $0.endedAtSec) > 0 }
                .map(\.label)
            guard let label = labelPriority.first(where: { activeLabels.contains($0) }) else {
                return nil
            }

            return AnnotationRow(
                label: label,
                start: rounded(start),
                end: rounded(end),
                motionSource: source
            )
        }
    }

    private static func updateAnnotationsCSV(
        at url: URL,
        recordingFileName: String,
        rows: [AnnotationRow]
    ) throws {
        var existingRows: [String] = []
        if FileManager.default.fileExists(atPath: url.path) {
            let existing = try String(contentsOf: url, encoding: .utf8)
            existingRows = existing
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .filter { $0 != annotationHeader }
                .filter { !$0.hasPrefix("\(csvEscape(recordingFileName)),") }
        }

        let newRows = rows.map { row in
            [
                csvEscape(recordingFileName),
                csvEscape(row.label.rawValue),
                format(row.start),
                format(row.end),
                csvEscape(row.motionSource.rawValue)
            ].joined(separator: ",")
        }

        let csv = ([annotationHeader] + existingRows + newRows).joined(separator: "\n") + "\n"
        try csv.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func writeLabeledActivityCSVs(from collected: CollectedSession, to folder: URL) throws -> Int {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        let rows = makeAnnotationRows(from: collected)
        let sessionPrefix = "\(collected.session.id)_"

        for label in labelPriority {
            let labelFolder = folder.appendingPathComponent(label.rawValue, isDirectory: true)
            if fileManager.fileExists(atPath: labelFolder.path) {
                let existingFiles = try fileManager.contentsOfDirectory(
                    at: labelFolder,
                    includingPropertiesForKeys: nil
                )
                for file in existingFiles where file.lastPathComponent.hasPrefix(sessionPrefix) {
                    try fileManager.removeItem(at: file)
                }
            }
        }

        var writtenCount = 0
        var labelIndexes: [ListeningLabel: Int] = [:]
        for row in rows {
            let segmentSamples = collected.samples
                .filter { $0.t >= row.start && $0.t < row.end }
                .sorted { $0.t < $1.t }
            guard segmentSamples.count >= 2 else { continue }

            let labelFolder = folder.appendingPathComponent(row.label.rawValue, isDirectory: true)
            try fileManager.createDirectory(at: labelFolder, withIntermediateDirectories: true)

            let index = (labelIndexes[row.label] ?? 0) + 1
            labelIndexes[row.label] = index
            let fileName = [
                collected.session.id,
                row.label.rawValue,
                "start\(milliseconds(row.start))",
                String(format: "%03d", index)
            ].joined(separator: "_") + ".csv"
            let fileURL = labelFolder.appendingPathComponent(fileName)
            try makeRecordingCSV(from: segmentSamples, rebasedTo: row.start)
                .write(to: fileURL, atomically: true, encoding: .utf8)
            writtenCount += 1
        }

        return writtenCount
    }

    private static func dominantMotionSource(_ samples: [MotionSample]) -> MotionSensorSource {
        let counts = Dictionary(grouping: samples.compactMap { $0.source }, by: { $0 }).mapValues { $0.count }
        return counts.max { $0.value < $1.value }?.key ?? .headphoneMotion
    }

    private static func makeRecordingCSV(from samples: [MotionSample], rebasedTo start: TimeInterval) -> String {
        let header = "t,ax,ay,az,gx,gy,gz,pitch,roll,yaw"
        let lines = samples.sorted { $0.t < $1.t }.map { sample in
            [
                format(max(0, sample.t - start)),
                format(sample.ax),
                format(sample.ay),
                format(sample.az),
                format(sample.gx ?? 0),
                format(sample.gy ?? 0),
                format(sample.gz ?? 0),
                format(sample.pitch ?? 0),
                format(sample.roll ?? 0),
                format(sample.yaw ?? 0)
            ].joined(separator: ",")
        }

        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    private static func milliseconds(_ value: TimeInterval) -> String {
        String(Int((value * 1000).rounded()))
    }

    private static func hasNoiseOverlap(start: TimeInterval, end: TimeInterval, noiseLabels: [LabelEvent]) -> Bool {
        noiseLabels.contains { label in
            overlap(start, end, label.startedAtSec, label.endedAtSec) / max(end - start, 0.0001) >= 0.5
        }
    }

    private static func overlap(_ aStart: TimeInterval, _ aEnd: TimeInterval, _ bStart: TimeInterval, _ bEnd: TimeInterval) -> TimeInterval {
        max(0, min(aEnd, bEnd) - max(aStart, bStart))
    }

    private static func rounded(_ value: TimeInterval) -> TimeInterval {
        (value * 1000).rounded() / 1000
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }

        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
