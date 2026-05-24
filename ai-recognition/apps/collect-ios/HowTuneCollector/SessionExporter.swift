import Foundation

struct ExportResult: Identifiable {
    var id = UUID()
    var createMLActivityDataURL: URL
    var activityCSVCount: Int
    var exportedAt: Date
}

enum SessionExporter {
    static func export(_ collected: CollectedSession) throws -> ExportResult {
        let folder = try exportFolder()
        let createMLActivityDataURL = folder.appendingPathComponent("CreateMLActivityData", isDirectory: true)
        let activityCSVCount = try writeLabeledActivityCSVs(from: collected, to: createMLActivityDataURL)

        return ExportResult(
            createMLActivityDataURL: createMLActivityDataURL,
            activityCSVCount: activityCSVCount,
            exportedAt: Date()
        )
    }

    static func exportFolder() throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("HowTuneExports", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private struct ActivityWindow {
        var label: ListeningLabel
        var start: TimeInterval
        var end: TimeInterval
    }

    private static let labelPriority: [ListeningLabel] = [.groove, .chill, .neutral]
    private static let activityWindowDuration: TimeInterval = 5.0
    private static let activityWindowDurationTolerance: TimeInterval = 0.3
    private static let activityWindowStride: TimeInterval = 2.5

    private static func makeActivityWindows(from collected: CollectedSession) -> [ActivityWindow] {
        let recordingEnd = collected.samples.map(\.t).max() ?? 0
        let labels = collected.labels
            .filter { $0.endedAtSec > $0.startedAtSec }

        return labels.flatMap { fixedWindows(for: $0, recordingEnd: recordingEnd) }
    }

    private static func fixedWindows(for label: LabelEvent, recordingEnd: TimeInterval) -> [ActivityWindow] {
        let start = max(0, label.startedAtSec)
        let end = min(label.endedAtSec, recordingEnd)
        guard end - start >= activityWindowDuration else { return [] }

        var windows: [ActivityWindow] = []
        var windowStart = start

        while windowStart + activityWindowDuration <= end + 0.001 {
            windows.append(
                ActivityWindow(
                    label: label.label,
                    start: rounded(windowStart),
                    end: rounded(windowStart + activityWindowDuration)
                )
            )
            windowStart += activityWindowStride
        }

        return windows
    }

    private static func writeLabeledActivityCSVs(from collected: CollectedSession, to folder: URL) throws -> Int {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try removeStaleLabelFolders(in: folder, fileManager: fileManager)
        let rows = makeActivityWindows(from: collected)
        let sessionPrefix = "\(collected.session.id)_"

        for label in labelPriority {
            let labelFolder = folder.appendingPathComponent(label.rawValue, isDirectory: true)
            try fileManager.createDirectory(at: labelFolder, withIntermediateDirectories: true)

            let existingFiles = try fileManager.contentsOfDirectory(
                at: labelFolder,
                includingPropertiesForKeys: nil
            )
            for file in existingFiles where file.lastPathComponent.hasPrefix(sessionPrefix) {
                try fileManager.removeItem(at: file)
            }
            try removeNonFixedWindowCSVs(in: labelFolder, fileManager: fileManager)
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

    private static func removeStaleLabelFolders(in folder: URL, fileManager: FileManager) throws {
        let allowedLabels = Set(labelPriority.map(\.rawValue))
        let existingItems = try fileManager.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.isDirectoryKey]
        )

        for item in existingItems where !allowedLabels.contains(item.lastPathComponent) {
            try fileManager.removeItem(at: item)
        }
    }

    private static func removeNonFixedWindowCSVs(in folder: URL, fileManager: FileManager) throws {
        let files = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        let minimumDuration = activityWindowDuration - activityWindowDurationTolerance
        let maximumDuration = activityWindowDuration + activityWindowDurationTolerance

        for file in files where file.pathExtension.lowercased() == "csv" {
            guard let duration = try csvDuration(at: file),
                  duration >= minimumDuration,
                  duration <= maximumDuration else {
                try fileManager.removeItem(at: file)
                continue
            }
        }
    }

    private static func csvDuration(at fileURL: URL) throws -> TimeInterval? {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = text.split(separator: "\n", omittingEmptySubsequences: true)
        guard let lastRow = rows.last, !lastRow.hasPrefix("t,") else { return nil }
        guard let value = lastRow.split(separator: ",").first else { return nil }
        return TimeInterval(String(value))
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

    private static func rounded(_ value: TimeInterval) -> TimeInterval {
        (value * 1000).rounded() / 1000
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}
