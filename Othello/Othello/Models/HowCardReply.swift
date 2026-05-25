import Foundation

struct HowCardReply: Decodable, Equatable, Identifiable {
    let id: String
    let howCardID: String
    let body: String
    let userID: String
    let userName: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case howCardID = "how_card_id"
        case body
        case userID = "user_id"
        case userName = "user_name"
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: String,
        howCardID: String,
        body: String,
        userID: String,
        userName: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.howCardID = howCardID
        self.body = body
        self.userID = userID
        self.userName = userName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.howCardID = try container.decode(String.self, forKey: .howCardID)
        self.body = try container.decode(String.self, forKey: .body)
        self.userID = try container.decode(String.self, forKey: .userID)
        self.userName = try container.decodeIfPresent(String.self, forKey: .userName)
            ?? container.decodeIfPresent(String.self, forKey: .displayName)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}
