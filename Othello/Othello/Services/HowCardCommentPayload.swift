import Foundation

struct HowCardCommentPayload: Encodable {
    let comment: String
    let songStart: TimeInterval
    let songEnd: TimeInterval
    let songID: String
    let artistID: String

    init(_ howCard: HowCardComment) {
        self.comment = howCard.comment
        self.songStart = howCard.songStart
        self.songEnd = howCard.songEnd
        self.songID = howCard.songID
        self.artistID = howCard.artistID
    }

    enum CodingKeys: String, CodingKey {
        case comment
        case songStart = "song_start"
        case songEnd = "song_end"
        case songID = "song_id"
        case artistID = "artist_id"
    }
}
