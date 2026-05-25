import SwiftUI
import Combine

@MainActor
final class ClipCreationViewModel: ObservableObject {
    let song: Song
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0.0
    @Published var clipStart: Double = 5.0
    @Published var clipEnd: Double = 35.0
    @Published var selectedTab: ClipTab = .clip

    let totalDuration: Double
    let waveformData: [CGFloat]

    private var timerCancellable: AnyCancellable?

    init(song: Song) {
        self.song = song
        let duration = Double(song.durationSeconds)
        self.totalDuration = duration
        let end = min(35.0, duration)
        self.clipEnd = end
        self.clipStart = min(5.0, end)
        var seed: UInt64 = 42
        self.waveformData = (0..<80).map { _ in
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let normalized = CGFloat((seed >> 33) & 0xFFFF) / CGFloat(0xFFFF)
            return 0.15 + normalized * 0.85
        }
    }

    func togglePlayback() {
        isPlaying.toggle()
        if isPlaying {
            if currentTime >= totalDuration {
                currentTime = 0
            }
            timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self else { return }
                    if self.currentTime < self.totalDuration {
                        self.currentTime += 0.1
                    } else {
                        self.isPlaying = false
                        self.timerCancellable = nil
                    }
                }
        } else {
            timerCancellable = nil
        }
    }

    func updateClipRange(startRatio: Double, endRatio: Double) {
        let s = min(max(startRatio, 0), 1)
        let e = min(max(endRatio, 0), 1)
        clipStart = min(s, e) * totalDuration
        clipEnd = max(s, e) * totalDuration
    }

    var clipDurationSeconds: Int {
        max(0, Int(clipEnd - clipStart))
    }

    var clipStartFormatted: String { formatTime(clipStart) }
    var clipEndFormatted: String { formatTime(clipEnd) }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

