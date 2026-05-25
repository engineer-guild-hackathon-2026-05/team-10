import FirebaseAuth
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
    let scores: [String: Double]
    let dominantAxis: String?
    struct HistoryItem: Encodable { let role: String; let content: String }
}

final class ChatAPIClient {
    static let shared = ChatAPIClient()
    private init() {}

    func chat(sessionID: String, event: ReactionEvent, messages: [HowChatMessage]) async throws -> ChatResponse {
        if isMockMode {
            return mockResponse(event: event, turn: messages.filter { $0.sender == .ai }.count)
        }

        var req = try await makeRequest(
            sessionID: sessionID,
            endpoint: "chat",
            timeoutInterval: 10,
            authRequired: false
        )
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

    func postHowCard(
        sessionID: String,
        event: ReactionEvent,
        messages: [HowChatMessage],
        selectedTags: [HowTag]
    ) async throws -> HowCardResponse {
        if isMockMode {
            return HowCardResponse(
                howTags: selectedTags.map(\.label),
                tagLabel: "\(selectedTags.first?.label ?? "groove")で聴く人",
                description: "音楽の\(selectedTags.first?.label ?? "groove")な瞬間に敏感に反応するリスナー。特に\(event.lyricLine ?? "この区間")で強く反応していました。",
                highlightSec: event.startTime
            )
        }
        var req = try await makeRequest(sessionID: sessionID, endpoint: "how-card", timeoutInterval: 15)
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

    private func makeRequest(
        sessionID: String,
        endpoint: String,
        timeoutInterval: TimeInterval,
        authRequired: Bool = true
    ) async throws -> URLRequest {
        let url = try makeURL(sessionID: sessionID, endpoint: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authRequired {
            let token = try await firebaseIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func makeURL(sessionID: String, endpoint: String) throws -> URL {
        guard var url = baseURL else {
            throw URLError(.badURL)
        }

        url.appendPathComponent("sessions")
        url.appendPathComponent(sessionID)
        url.appendPathComponent(endpoint)
        return url
    }

    private func firebaseIDToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAPIError.notAuthenticated
        }

        return try await withCheckedThrowingContinuation { continuation in
            user.getIDToken { token, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: FirebaseAPIError.notAuthenticated)
                }
            }
        }
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
            tags: event.tags.map(\.rawValue),
            intensity: event.intensity,
            lyric: event.lyricLine,
            history: messages.map {
                .init(role: $0.sender == .ai ? "assistant" : "user", content: $0.text)
            },
            scores: event.score.asDictionary,
            dominantAxis: event.score.dominant?.id
        )
    }

    private func mockResponse(event: ReactionEvent, turn: Int) -> ChatResponse {
        let dominant = event.score.dominant?.id ?? event.tags.first?.rawValue ?? "groove"
        let time = formatTime(event.startTime)

        switch turn {
        case 0:
            switch dominant {
            case "groove", "hype":
                return ChatResponse(
                    question: "\(time)あたり、体が動いていましたね。リズムに乗っていた感じでしたか？",
                    choices: ["自然と体が動いた", "テンションが上がった", "ビートが気持ちよかった"]
                )
            case "hit", "immersion":
                return ChatResponse(
                    question: "\(time)あたり、何かが刺さった瞬間でしたか？",
                    choices: ["歌詞が刺さった", "メロディが響いた", "音が重なった瞬間", "なんかわからないけど刺さった"]
                )
            case "chill", "afterglow":
                return ChatResponse(
                    question: "\(time)あたり、静かに聴き入っていましたね。どんな感じでしたか？",
                    choices: ["余韻に浸っていた", "心が落ち着いた", "世界が広がった感じ"]
                )
            default:
                return ChatResponse(
                    question: "\(time)あたり、身体が反応していました。どんな感じでしたか？",
                    choices: ["体が動いた", "何かが刺さった", "静かに入り込んだ"]
                )
            }
        default:
            switch dominant {
            case "groove", "hype":
                return ChatResponse(
                    question: "その動き、音楽のどの部分に引っ張られていましたか？",
                    choices: ["ベースやドラムのリズム", "サビの盛り上がり", "音の波に乗っていた"]
                )
            case "hit", "immersion":
                return ChatResponse(
                    question: "その感覚、もう少し言葉にするとしたら？",
                    choices: ["突き刺さる感じ", "じんわり染み込む感じ", "胸が締め付けられた", "ハッとした"]
                )
            case "chill", "afterglow":
                return ChatResponse(
                    question: "その余韻、いつまでも残る感じがしましたか？",
                    choices: ["曲が終わっても残った", "静寂が心地よかった", "もう一度聴きたくなった"]
                )
            default:
                return ChatResponse(
                    question: "この感覚、一言で表すとしたら？",
                    choices: ["体が動く感じ", "刺さる感じ", "浮かぶような感じ", "沁みる感じ"]
                )
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
