struct HowCardReplyResponseEnvelope: Decodable {
    let reply: HowCardReply
    let replyCount: Int

    enum CodingKeys: String, CodingKey {
        case reply
        case replyCount = "reply_count"
    }
}
