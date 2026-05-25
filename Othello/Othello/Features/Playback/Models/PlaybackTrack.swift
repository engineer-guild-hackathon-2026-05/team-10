import Foundation
import MusicKit

struct PlaybackTrack: Identifiable, Equatable {
    let id: MusicItemID
    let musicKitID: String
    let title: String
    let artistName: String
    let albumTitle: String?
    let isrc: String?
    let hasLyrics: Bool
    let duration: TimeInterval?
    let artworkURL: URL?

    static func == (lhs: PlaybackTrack, rhs: PlaybackTrack) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlaybackTrack {
    init(song: MusicKit.Song) {
        self.id = song.id
        self.musicKitID = song.id.rawValue
        self.title = song.title
        self.artistName = song.artistName
        self.albumTitle = song.albumTitle
        self.isrc = song.isrc
        self.hasLyrics = song.hasLyrics
        self.duration = song.duration
        self.artworkURL = song.artwork?.url(width: 600, height: 600)
    }
}
