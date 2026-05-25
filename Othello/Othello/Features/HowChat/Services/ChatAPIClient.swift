import Foundation

struct ChatResponse: Decodable {
    let question: String
    let choices: [String]
}

struct HowCardResponse: Decodable {
    let howTags: [String]
    let tagLabel: String
    let description: String
    let highlightSec: Double
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

    func chat(event: ReactionEvent, messages: [HowChatMessage]) async throws -> ChatResponse {
        if isMockMode {
            return mockResponse(event: event, turn: messages.filter { $0.sender == .ai }.count)
        }

        guard let baseURL else {
            throw URLError(.badURL)
        }

        guard let url = URL(string: "/sessions/default/chat", relativeTo: baseURL)?.absoluteURL else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url, timeoutInterval: 10)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = buildPayload(event: event, messages: messages)
        req.httpBody = try JSONEncoder().encode(payload)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(ChatResponse.self, from: data)
    }

    private var baseURL: URL? {
        guard
            let rawValue = EnvironmentValueProvider.value(forKey: "API_BASE_URL")?.trimmingCharacters(in: .whitespacesAndNewlines),
            !rawValue.isEmpty
        else {
            return nil
        }

        return URL(string: rawValue)
    }

    func postHowCard(event: ReactionEvent, messages: [HowChatMessage], selectedTags: [HowTag]) async throws -> HowCardResponse {
        if isMockMode {
            return HowCardResponse(
                howTags: selectedTags.map(\.label),
                tagLabel: "\(selectedTags.first?.label ?? "groove")で聴く人",
                description: "音楽の\(selectedTags.first?.label ?? "groove")な瞬間に敏感に反応するリスナー。特に\(event.lyricLine ?? "この区間")で強く反応していました。",
                highlightSec: event.startTime
            )
        }
        let url = URL(string: "\(baseURL)/sessions/demo/how-card")!
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "songTitle": "HowTune Demo",
            "reactions": [[
                "startSec": event.startTime,
                "endSec": event.endTime,
                "scores": Dictionary(uniqueKeysWithValues: event.tags.map { ($0.label, 0.8) })
            ]],
            "chatHistory": messages.map { ["role": $0.sender == .ai ? "assistant" : "user", "content": $0.text] }
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let wrapper = try JSONDecoder().decode([String: HowCardResponse].self, from: data)
        guard let card = wrapper["howCard"] else { throw URLError(.cannotParseResponse) }
        return card
    }

    private var isMockMode: Bool {
        if isEnabled(EnvironmentValueProvider.value(forKey: "HOWTUNE_CHAT_MOCK")) {
            return true
        }

        #if DEBUG
        return baseURL == nil
        #else
        return false
        #endif
    }

    private func isEnabled(_ value: String?) -> Bool {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
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
