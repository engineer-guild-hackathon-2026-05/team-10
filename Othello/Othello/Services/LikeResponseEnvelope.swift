struct LikeResponseEnvelope: Decodable {
    let goods: Int

    enum CodingKeys: String, CodingKey {
        case goods
        case likes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.goods = try container.decodeIfPresent(Int.self, forKey: .goods)
            ?? container.decodeIfPresent(Int.self, forKey: .likes)
            ?? 0
    }
}
