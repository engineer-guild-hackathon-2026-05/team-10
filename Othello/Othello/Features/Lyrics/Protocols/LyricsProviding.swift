import Foundation

protocol LyricsProviding {
    func fetchLyrics(for query: LyricsTrackQuery) async throws -> SynchronizedLyrics
}
