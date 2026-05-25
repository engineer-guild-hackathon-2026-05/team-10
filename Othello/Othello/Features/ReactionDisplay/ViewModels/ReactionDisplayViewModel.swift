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

    func startSession(sensorAvailable: Bool) {
        isSessionActive = true
        isSensorAvailable = sensorAvailable
        pendingScore = .empty
        score = .empty
        startDisplayUpdateTimer()
    }

    func stopSession(presentTimeline: Bool = true) {
        let wasSessionActive = isSessionActive
        isSessionActive = false
        stopDisplayUpdateTimer()
        pendingScore = .empty
        withAnimation(.easeOut(duration: 0.6)) { score = .empty }
        showTimeline = presentTimeline && wasSessionActive
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
}
