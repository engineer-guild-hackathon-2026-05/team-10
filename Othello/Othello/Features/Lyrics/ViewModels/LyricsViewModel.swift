import Combine
import Foundation

@MainActor
final class LyricsViewModel: ObservableObject {
    @Published private(set) var state: LyricsLoadingState = .idle
    @Published private(set) var lyrics: SynchronizedLyrics?
    @Published private(set) var selectedReactionLine: ReactionLyricMatch?

    private let provider: LyricsProviding

    init(provider: LyricsProviding? = nil) {
        self.provider = provider ?? MusixmatchLyricsProvider()
    }

    func loadLyrics(for query: LyricsTrackQuery) async {
        state = .loading
        selectedReactionLine = nil

        do {
            let lyrics = try await provider.fetchLyrics(for: query)
            self.lyrics = lyrics
            state = .loaded
        } catch let error as LyricsError {
            lyrics = nil
            state = unavailableState(for: error)
        } catch {
            lyrics = nil
            state = .failed(error.localizedDescription)
        }
    }

    func line(forReactionAt playbackTime: TimeInterval) -> ReactionLyricMatch {
        let match = ReactionLyricMatch(
            reactionTime: playbackTime,
            line: lyrics?.line(at: playbackTime)
        )
        selectedReactionLine = match
        return match
    }

    func clear() {
        state = .idle
        lyrics = nil
        selectedReactionLine = nil
    }

    private func unavailableState(for error: LyricsError) -> LyricsLoadingState {
        switch error {
        case .trackNotFound, .restrictedLyrics, .emptyLyricsBody, .synchronizedLyricsUnavailable, .lookupFailed:
            return .unavailable(error.localizedDescription)
        case .missingAPIKey, .invalidRequest, .invalidResponse, .requestFailed, .apiStatus:
            return .failed(error.localizedDescription)
        }
    }
}
