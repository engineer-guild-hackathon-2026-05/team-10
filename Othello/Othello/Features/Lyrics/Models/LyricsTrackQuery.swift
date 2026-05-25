import Foundation

#if canImport(MusicKit)
import MusicKit
#endif

struct LyricsTrackQuery: Equatable {
    let musicKitID: String?
    let title: String
    let artistName: String
    let albumName: String?
    let isrc: String?
    let duration: TimeInterval?

    init(
        musicKitID: String? = nil,
        title: String,
        artistName: String,
        albumName: String? = nil,
        isrc: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.musicKitID = musicKitID
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
            musicKitID: track.musicKitID,
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
            musicKitID: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            albumName: song.albumTitle,
            isrc: song.isrc,
            duration: song.duration
        )
    }
}
#endif
