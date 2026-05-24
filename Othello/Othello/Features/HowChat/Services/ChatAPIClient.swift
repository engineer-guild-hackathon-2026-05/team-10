import Foundation

struct ChatResponse: Decodable {
    let question: String
    let choices: [String]
}

private struct ChatPayload: Encodable {
    let startTime: TimeInterval
    let tags: [String]
    let intensity: Double
    let lyric: String?
    let history: [HistoryItem]
    struct HistoryItem: Encodable { let role: String; let content: String }
}

final class ChatAPIClient {
    static let shared = ChatAPIClient()
    private init() {}

    private let baseURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
        ?? "http://localhost:3000"

    func chat(event: ReactionEvent, messages: [HowChatMessage]) async throws -> ChatResponse {
        if isMockMode {
            return mockResponse(event: event, turn: messages.filter { $0.sender == .ai }.count)
        }
        let url = URL(string: "\(baseURL)/sessions/mock/chat")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = buildPayload(event: event, messages: messages)
        req.httpBody = try JSONEncoder().encode(payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    private var isMockMode: Bool {
        ProcessInfo.processInfo.environment["API_BASE_URL"] == nil
    }

    private func buildPayload(event: ReactionEvent, messages: [HowChatMessage]) -> ChatPayload {
        ChatPayload(
            startTime: event.startTime,
            tags: event.tags.map(\.label),
            intensity: event.intensity,
            lyric: event.lyricLine,
            history: messages.map {
                .init(role: $0.sender == .ai ? "assistant" : "user", content: $0.text)
            }
        )
    }

    private func mockResponse(event: ReactionEvent, turn: Int) -> ChatResponse {
        let dominant = event.tags.first?.label ?? "何か"
        switch turn {
        case 0:
            return ChatResponse(
                question: "\(formatTime(event.startTime))あたり、身体が反応していました。\(dominant)な感じでしたか？",
                choices: ["そう、ノってた", "メロディが刺さった", "なんか上がった"]
            )
        case 1:
            return ChatResponse(
                question: "その瞬間、音楽のどの要素に反応していたと思いますか？",
                choices: ["リズム・ビート", "メロディライン", "歌詞の言葉", "音の重なり"]
            )
        default:
            return ChatResponse(
                question: "この感覚、一言で表すとしたら？",
                choices: ["突き刺さる感じ", "体が動く感じ", "浮かぶような感じ", "沁みる感じ"]
            )
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
