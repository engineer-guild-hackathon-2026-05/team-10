import Foundation
import SwiftUI

struct HomeDashboardComment: Identifiable, Equatable {
    let id: String
    let howCard: HowCardComment
    let song: Song
    let artist: Artist
    let artworkURL: URL?

    init(
        howCard: HowCardComment,
        songTitle: String,
        artistName: String,
        artworkURL: URL?,
        durationSeconds: Int,
        gradientColors: [Color]
    ) {
        let song = Song(
            id: Self.stableUUID(namespace: "home-song", key: Self.identityKey(howCard.songID, fallback: howCard.id)),
            title: songTitle,
            artistName: artistName,
            gradientColors: gradientColors,
            durationSeconds: durationSeconds,
            musicKitID: Self.musicKitID(from: howCard.songID),
            firestoreLookupID: Self.nonEmpty(howCard.songID),
            artistID: Self.nonEmpty(howCard.artistID),
            artworkURL: artworkURL
        )

        self.id = howCard.id
        self.howCard = howCard
        self.song = song
        self.artist = Artist(
            id: Self.stableUUID(
                namespace: "home-artist",
                key: Self.identityKey(howCard.artistID, fallback: "\(artistName)-\(howCard.id)")
            ),
            name: artistName,
            listeningCount: "\(max(howCard.goods, 0))件の反応",
            tag: "コメント",
            gradientColors: gradientColors,
            artworkURL: artworkURL,
            songs: [song]
        )
        self.artworkURL = artworkURL
    }

    static func == (lhs: HomeDashboardComment, rhs: HomeDashboardComment) -> Bool {
        lhs.id == rhs.id
    }

    private static func identityKey(_ key: String, fallback: String) -> String {
        let normalizedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedKey.isEmpty {
            return normalizedKey
        }
        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nonEmpty(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func musicKitID(from value: String) -> String? {
        guard let trimmed = nonEmpty(value),
              trimmed.count <= 64,
              trimmed.allSatisfy(\.isNumber) else {
            return nil
        }
        return trimmed
    }

    private static func stableUUID(namespace: String, key: String) -> UUID {
        let seed = "\(namespace):\(key)"
        let upper = stableHash(seed + ":0")
        let lower = stableHash(seed + ":1")
        return UUID(uuid: (
            UInt8((upper >> 56) & 0xff),
            UInt8((upper >> 48) & 0xff),
            UInt8((upper >> 40) & 0xff),
            UInt8((upper >> 32) & 0xff),
            UInt8((upper >> 24) & 0xff),
            UInt8((upper >> 16) & 0xff),
            UInt8((upper >> 8) & 0xff),
            UInt8(upper & 0xff),
            UInt8((lower >> 56) & 0xff),
            UInt8((lower >> 48) & 0xff),
            UInt8((lower >> 40) & 0xff),
            UInt8((lower >> 32) & 0xff),
            UInt8((lower >> 24) & 0xff),
            UInt8((lower >> 16) & 0xff),
            UInt8((lower >> 8) & 0xff),
            UInt8(lower & 0xff)
        ))
    }

    private static func stableHash(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return hash
    }
}
