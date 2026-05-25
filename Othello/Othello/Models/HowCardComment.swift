import Foundation

struct HowCardComment: Codable, Equatable, Identifiable {
    var documentID: String?
    var comment: String
    var songStart: TimeInterval
    var songEnd: TimeInterval
    var songID: String
    var artistID: String
    var userID: String
    var userName: String?
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
        userName: String? = nil,
        goods: Int = 0
    ) {
        self.documentID = documentID
        self.comment = comment
        self.songStart = songStart
        self.songEnd = songEnd
        self.songID = songID
        self.artistID = artistID
        self.userID = userID
        self.userName = userName
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
        case userName = "user_name"
        case displayName = "display_name"
        case goods
        case likes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.documentID = try container.decodeIfPresent(String.self, forKey: .documentID)
        self.comment = try container.decode(String.self, forKey: .comment)
        self.songStart = try container.decodeIfPresent(TimeInterval.self, forKey: .songStart) ?? 0
        self.songEnd = try container.decodeIfPresent(TimeInterval.self, forKey: .songEnd) ?? 0
        self.songID = try container.decode(String.self, forKey: .songID)
        self.artistID = try container.decode(String.self, forKey: .artistID)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
            ?? container.decodeIfPresent(String.self, forKey: .displayName)
        self.goods = try container.decodeIfPresent(Int.self, forKey: .goods)
            ?? container.decodeIfPresent(Int.self, forKey: .likes)
            ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(documentID, forKey: .documentID)
        try container.encode(comment, forKey: .comment)
        try container.encode(songStart, forKey: .songStart)
        try container.encode(songEnd, forKey: .songEnd)
        try container.encode(songID, forKey: .songID)
        try container.encode(artistID, forKey: .artistID)
        try container.encode(userID, forKey: .userID)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encode(goods, forKey: .goods)
    }
}
