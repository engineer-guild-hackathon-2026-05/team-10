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

    init(event: ReactionEvent) {
        self.event = event
        self.sessionID = event.id.uuidString
    }

    func start() {
        guard messages.isEmpty else { return }
        Task { await sendToAI(userMessage: nil) }
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
        guard turnCount < 3 else {
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
