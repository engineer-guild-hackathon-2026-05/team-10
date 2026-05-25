import Foundation
import Combine

@MainActor
final class HowChatViewModel: ObservableObject {
    @Published var messages: [HowChatMessage] = []
    @Published var choices: [HowChatChoice] = []
    @Published var freeInputText: String = ""
    @Published var state: ChatState = .idle
    @Published var turnCount: Int = 0

    enum ChatState { case idle, loading, waitingReply, done, error }

    let event: ReactionEvent
    let sessionID: String
    private let maximumDialogueTurns = 2
    /// 1回目の「決めうち」問いかけ（FR-RES-02）。peak がある時のみ設定され、その場合 turn0 は LLM を呼ばない。
    private let scriptedFirstPrompt: HowResonancePromptBuilder.Prompt?

    init(event: ReactionEvent, peak: PeakMoment? = nil) {
        self.event = event
        self.sessionID = event.id.uuidString
        if let peak {
            self.scriptedFirstPrompt = HowResonancePromptBuilder.firstPrompt(peak: peak)
        } else {
            self.scriptedFirstPrompt = nil
        }
    }

    func start() {
        guard messages.isEmpty else { return }
        if let scriptedFirstPrompt {
            // 1回目は決めうち（ピーク地点の固定問いかけ）。2回目以降は LLM。
            messages.append(HowChatMessage(sender: .ai, text: scriptedFirstPrompt.question))
            choices = scriptedFirstPrompt.choices.map { HowChatChoice(label: $0) }
            state = .waitingReply
        } else {
            Task { await sendToAI(userMessage: nil) }
        }
    }

    func selectChoice(_ choice: HowChatChoice) {
        submitReply(choice.label)
    }

    func submitFreeInput() {
        let text = freeInputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        freeInputText = ""
        submitReply(text)
    }

    private func submitReply(_ text: String) {
        choices = []
        messages.append(HowChatMessage(sender: .user, text: text))
        turnCount += 1
        guard turnCount < maximumDialogueTurns else {
            state = .done
            return
        }
        Task { await sendToAI(userMessage: text) }
    }

    private func sendToAI(userMessage: String?) async {
        state = .loading
        do {
            let response = try await ChatAPIClient.shared.chat(sessionID: sessionID, event: event, messages: messages)
            messages.append(HowChatMessage(sender: .ai, text: response.question))
            choices = response.choices.map { HowChatChoice(label: $0) }
            state = .waitingReply
        } catch {
            // フォールバック: 手動入力を促す
            messages.append(HowChatMessage(sender: .ai, text: "この瞬間、どんな感じがしましたか？"))
            choices = []
            state = .waitingReply
        }
    }
}
