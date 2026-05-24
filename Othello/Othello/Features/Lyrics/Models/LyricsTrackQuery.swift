import Foundation

#if canImport(MusicKit)
import MusicKit
#endif

struct LyricsTrackQuery: Equatable {
    let title: String
    let artistName: String
    let albumName: String?
    let isrc: String?
    let duration: TimeInterval?

    init(
        title: String,
        artistName: String,
        albumName: String? = nil,
        isrc: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.title = title
        self.artistName = artistName
        self.albumName = albumName
        self.isrc = isrc
        self.duration = duration
    }

}

extension LyricsTrackQuery {
    init(playbackTrack track: PlaybackTrack) {
        self.init(
            title: track.title,
            artistName: track.artistName,
            albumName: track.albumTitle,
            isrc: track.isrc,
            duration: track.duration
        )
    }
}

#if canImport(MusicKit)
extension LyricsTrackQuery {
    init(musicKitSong song: Song) {
        self.init(
            title: song.title,
            artistName: song.artistName,
            albumName: song.albumTitle,
            isrc: song.isrc,
            duration: song.duration
        )
    }
}
#endif
