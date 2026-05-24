import Foundation
import Combine
import SwiftUI

@MainActor
final class ReactionDisplayViewModel: ObservableObject {

    @Published private(set) var score: ReactionScore = .empty
    @Published private(set) var isSessionActive: Bool = false
    @Published private(set) var isSensorAvailable: Bool = false
    @Published var showTimeline: Bool = false

    @Published var selectedLyric: String? = nil
    @Published var selectedLyricTranslation: String? = nil
    @Published var selectedHowTag: HowTag? = nil
    @Published var showHowTagSheet: Bool = false

    private var displayUpdateTimer: AnyCancellable?
    private var pendingScore: ReactionScore = .empty
    private var mockTimer: AnyCancellable?

    func startSession(sensorAvailable: Bool) {
        isSessionActive = true
        isSensorAvailable = sensorAvailable
        startDisplayUpdateTimer()
        if sensorAvailable { startMockSensorSimulation() }
    }

    func stopSession() {
        isSessionActive = false
        stopDisplayUpdateTimer()
        stopMockSensorSimulation()
        withAnimation(.easeOut(duration: 0.6)) { score = .empty }
        showTimeline = true
    }

    func updateScore(_ newScore: ReactionScore) {
        pendingScore = newScore
    }

    private func startDisplayUpdateTimer() {
        displayUpdateTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.isSessionActive else { return }
                withAnimation(.easeInOut(duration: 0.15)) { self.score = self.pendingScore }
            }
    }

    private func stopDisplayUpdateTimer() {
        displayUpdateTimer?.cancel()
        displayUpdateTimer = nil
    }

    private var mockPhase: Double = 0

    private func startMockSensorSimulation() {
        mockTimer = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.mockPhase += 0.15
                let t = self.mockPhase
                self.pendingScore = ReactionScore(
                    groove:    max(0, sin(t * 1.1) * 0.6 + 0.3),
                    hype:      max(0, sin(t * 0.7 + 1.0) * 0.5 + 0.2),
                    chill:     max(0, cos(t * 0.5 + 0.5) * 0.4 + 0.3),
                    immersion: max(0, sin(t * 0.9 + 2.0) * 0.55 + 0.25),
                    hit:       max(0, sin(t * 1.3 + 0.3) * 0.35 + 0.1),
                    afterglow: max(0, cos(t * 0.6 + 1.5) * 0.3 + 0.15)
                )
            }
    }

    private func stopMockSensorSimulation() {
        mockTimer?.cancel()
        mockTimer = nil
        mockPhase = 0
    }
}
