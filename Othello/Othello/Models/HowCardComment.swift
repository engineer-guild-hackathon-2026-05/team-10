import FirebaseFirestore
import Foundation

struct HowCardComment: Codable, Equatable, Identifiable {
    @DocumentID var documentID: String?
    var comment: String
    var songID: String
    var artistID: String
    var userID: String
    var goods: Int

    var id: String {
        documentID ?? "\(songID)-\(artistID)-\(userID)"
    }

    init(
        documentID: String? = nil,
        comment: String,
        songID: String,
        artistID: String,
        userID: String,
        goods: Int = 0
    ) {
        self._documentID = DocumentID(wrappedValue: documentID)
        self.comment = comment
        self.songID = songID
        self.artistID = artistID
        self.userID = userID
        self.goods = goods
    }

    enum CodingKeys: String, CodingKey {
        case documentID
        case comment
        case songID = "song_id"
        case artistID = "artist_id"
        case userID = "user_id"
        case goods
    }
}
