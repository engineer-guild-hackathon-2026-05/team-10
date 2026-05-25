import Foundation
import SwiftUI

struct Song: Identifiable {
    let id: UUID
    let title: String
    let artistName: String
    let gradientColors: [Color]
    let durationSeconds: Int
    let musicKitID: String?
    let artistID: String
    let artworkURL: URL?

    init(
        id: UUID,
        title: String,
        artistName: String,
        gradientColors: [Color],
        durationSeconds: Int,
        musicKitID: String? = nil,
        artistID: String? = nil,
        artworkURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.gradientColors = gradientColors
        self.durationSeconds = durationSeconds
        self.musicKitID = musicKitID
        self.artistID = artistID ?? Song.stableIdentifier(from: artistName)
        self.artworkURL = artworkURL
    }

    var firestoreSongID: String {
        musicKitID ?? "\(artistID)-\(Song.stableIdentifier(from: title))"
    }

    var firestoreArtistID: String {
        artistID
    }

    var duration: TimeInterval {
        TimeInterval(durationSeconds)
    }

    private static func stableIdentifier(from value: String) -> String {
        let normalized = value
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: "-", options: .regularExpression)
            .replacingOccurrences(of: "[^a-z0-9\\-ぁ-んァ-ン一-龥ー&.]", with: "", options: .regularExpression)
        return normalized.isEmpty ? "unknown" : normalized
    }
}

extension Song: Hashable {
    static func == (lhs: Song, rhs: Song) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Song {
    init(playbackTrack: PlaybackTrack, fallback: Song) {
        self.init(
            id: fallback.id,
            title: playbackTrack.title,
            artistName: playbackTrack.artistName,
            gradientColors: fallback.gradientColors,
            durationSeconds: Int(playbackTrack.duration ?? fallback.duration),
            musicKitID: playbackTrack.musicKitID,
            artistID: fallback.artistID,
            artworkURL: playbackTrack.artworkURL
        )
    }
}
