struct UserSeedProfile: Encodable, Equatable {
    let userID: String
    let email: String?
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case email
        case displayName = "display_name"
    }
}

struct UserSeedRequestPayload: Encodable {
    let users: [UserSeedProfile]
}
