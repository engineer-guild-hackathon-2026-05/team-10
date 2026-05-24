import Foundation

protocol LyricsProviding {
    func fetchSynchronizedLyrics(for query: LyricsTrackQuery) async throws -> SynchronizedLyrics
}
