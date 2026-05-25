import Foundation

struct UserProfile: Codable, Equatable, Identifiable {
    var id: String?
    var userID: String
    var email: String
    var displayName: String?
    var createdAt: String?
    var updatedAt: String?

    init(
        id: String? = nil,
        userID: String,
        email: String,
        displayName: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userID = userID
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
