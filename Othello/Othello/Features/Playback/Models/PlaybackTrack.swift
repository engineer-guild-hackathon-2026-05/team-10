import Foundation
import MusicKit

struct PlaybackTrack: Identifiable, Equatable {
    let id: MusicItemID
    let title: String
    let artistName: String
    let albumTitle: String?
    let duration: TimeInterval?
    let artworkURL: URL?

    static func == (lhs: PlaybackTrack, rhs: PlaybackTrack) -> Bool {
        lhs.id == rhs.id
    }
}

extension PlaybackTrack {
    init(song: Song) {
        self.id = song.id
        self.title = song.title
        self.artistName = song.artistName
        self.albumTitle = song.albumTitle
        self.duration = song.duration
        self.artworkURL = song.artwork?.url(width: 500, height: 500)
    }
}
