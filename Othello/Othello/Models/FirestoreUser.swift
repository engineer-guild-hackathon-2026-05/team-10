import FirebaseFirestore
import Foundation

struct FirestoreUser: Codable, Equatable, Identifiable {
    @DocumentID var documentID: String?
    var userID: String
    var email: String
    @ExplicitNull var displayName: String?
    var createdAt: Date
    var updatedAt: Date

    var id: String {
        documentID ?? userID
    }

    init(
        documentID: String? = nil,
        userID: String,
        email: String,
        displayName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self._documentID = DocumentID(wrappedValue: documentID)
        self.userID = userID
        self.email = email
        self._displayName = ExplicitNull(wrappedValue: displayName)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case documentID
        case userID = "user_id"
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
