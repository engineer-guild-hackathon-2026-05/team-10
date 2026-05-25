import Foundation

struct HowCardComment: Codable, Equatable, Identifiable {
    var documentID: String?
    var comment: String
    var songStart: TimeInterval
    var songEnd: TimeInterval
    var songID: String
    var artistID: String
    var userID: String
    var goods: Int

    var id: String {
        documentID ?? "\(songID)-\(songStart)-\(songEnd)-\(artistID)-\(userID)"
    }

    init(
        documentID: String? = nil,
        comment: String,
        songStart: TimeInterval = 0,
        songEnd: TimeInterval = 0,
        songID: String,
        artistID: String,
        userID: String = UUID().uuidString,
        goods: Int = 0
    ) {
        self.documentID = documentID
        self.comment = comment
        self.songStart = songStart
        self.songEnd = songEnd
        self.songID = songID
        self.artistID = artistID
        self.userID = userID
        self.goods = goods
    }

    enum CodingKeys: String, CodingKey {
        case documentID = "id"
        case comment
        case songStart = "song_start"
        case songEnd = "song_end"
        case songID = "song_id"
        case artistID = "artist_id"
        case userID = "user_id"
        case goods
    }
}
