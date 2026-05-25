import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class CollectorViewModel: ObservableObject {
    enum Phase {
        case start
        case recording
        case review
    }

    @Published var phase: Phase = .start
    @Published var selectedSong: DemoSong = DemoSong.catalog[0]
    @Published var elapsed: TimeInterval = 0
    @Published var labels: [LabelEvent] = []
    @Published var collectedSession: CollectedSession?
    @Published var exportResult: ExportResult?
    @Published var exportError: String?

    let motion = MotionRecorder()
    let audio = DemoAudioPlayer()

    private var sessionRecord: SessionRecord?
    private var sessionStartedAt: Date?
    private var timer: Timer?

    var progress: Double {
        min(1, elapsed / max(selectedSong.durationSec, 0.1))
    }

    func startSession() {
        let startedAt = Date()
        let sessionId = makeSessionId(startedAt)
        let deviceInfo = makeDeviceInfo()

        labels = []
        collectedSession = nil
        exportResult = nil
        exportError = nil
        elapsed = 0
        sessionStartedAt = startedAt
        sessionRecord = SessionRecord(
            id: sessionId,
            userId: "anonymous",
            songId: selectedSong.id,
            startedAt: startedAt,
            endedAt: nil,
            device: deviceInfo
        )

        phase = .recording
        motion.start(sessionStartedAt: startedAt)
        audio.play(song: selectedSong)
        startTimer()
    }

    func addLabel(_ label: ListeningLabel) {
        guard let sessionRecord else { return }
        let start = max(0, elapsed - label.defaultBeforeSec)
        let end = min(selectedSong.durationSec, elapsed + label.defaultAfterSec)
        labels.append(
            LabelEvent(
                id: "label_\(UUID().uuidString.prefix(8))",
                sessionId: sessionRecord.id,
                label: label,
                startedAtSec: rounded(start),
                endedAtSec: rounded(end),
                source: "realtime_button",
                confidence: nil
            )
        )
    }

    func deleteLabel(_ label: LabelEvent) {
        labels.removeAll { $0.id == label.id }
    }

    func updateLabel(_ label: LabelEvent, start: TimeInterval? = nil, end: TimeInterval? = nil) {
        guard let index = labels.firstIndex(where: { $0.id == label.id }) else { return }
        var updatedLabel = labels[index]
        if let start {
            updatedLabel.startedAtSec = rounded(max(0, min(start, selectedSong.durationSec)))
        }
        if let end {
            updatedLabel.endedAtSec = rounded(max(0, min(end, selectedSong.durationSec)))
        }
        if updatedLabel.endedAtSec < updatedLabel.startedAtSec {
            let originalStart = updatedLabel.startedAtSec
            updatedLabel.startedAtSec = updatedLabel.endedAtSec
            updatedLabel.endedAtSec = originalStart
        }
        labels[index] = updatedLabel
    }

    func finishSession() {
        stopTimer()
        audio.stop()
        motion.stop()

        guard var sessionRecord else { return }
        sessionRecord.endedAt = Date()
        self.sessionRecord = sessionRecord

        let collected = CollectedSession(
            session: sessionRecord,
            samples: motion.samples,
            labels: labels.sorted { $0.startedAtSec < $1.startedAtSec }
        )
        collectedSession = collected
        export(collected)
        phase = .review
    }

    func reset() {
        stopTimer()
        audio.stop()
        motion.reset()
        sessionRecord = nil
        sessionStartedAt = nil
        elapsed = 0
        labels = []
        collectedSession = nil
        exportResult = nil
        exportError = nil
        phase = .start
    }

    func saveAgain() {
        guard let collectedSession else { return }
        export(collectedSession)
    }

    private func export(_ collected: CollectedSession) {
        do {
            exportResult = try SessionExporter.export(collected)
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let sessionStartedAt = self.sessionStartedAt else { return }
                self.elapsed = min(Date().timeIntervalSince(sessionStartedAt), self.selectedSong.durationSec)

                if self.elapsed >= self.selectedSong.durationSec {
                    self.finishSession()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func makeSessionId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "session_\(formatter.string(from: date))"
    }

    private func makeDeviceInfo() -> DeviceInfo {
        #if canImport(UIKit)
        let device = UIDevice.current
        return DeviceInfo(
            name: device.name,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            model: device.model
        )
        #else
        return DeviceInfo(
            name: Host.current().localizedName ?? "Mac",
            systemName: "macOS",
            systemVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            model: "Mac"
        )
        #endif
    }

    private func rounded(_ value: TimeInterval) -> TimeInterval {
        (value * 1000).rounded() / 1000
    }
}
