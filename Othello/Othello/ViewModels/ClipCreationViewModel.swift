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
    @Published var commentText: String = ""
    @Published private(set) var isPosting: Bool = false
    @Published var postErrorMessage: String?
    @Published private(set) var postedCardID: String?

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
                        self.currentTime = min(self.currentTime + 0.1, self.totalDuration)
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

    @discardableResult
    func postHowCard() async -> Bool {
        guard !isPosting else { return false }

        let comment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !comment.isEmpty else {
            postErrorMessage = "コメントを入力してください"
            return false
        }

        isPosting = true
        postErrorMessage = nil
        postedCardID = nil
        defer { isPosting = false }

        do {
            let howCard = HowCardComment(
                comment: comment,
                songStart: clipStart,
                songEnd: clipEnd,
                songID: song.firestoreSongID,
                artistID: song.firestoreArtistID,
                userID: "me"
            )
            postedCardID = try await FirebaseAPI.shared.createHowCard(howCard)
            return true
        } catch {
            postedCardID = nil
            postErrorMessage = "Howカードを投稿できませんでした"
            return false
        }
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
