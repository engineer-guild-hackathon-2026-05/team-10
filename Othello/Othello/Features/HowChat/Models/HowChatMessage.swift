import Foundation

enum HowChatSender { case ai, user }

struct HowChatMessage: Identifiable {
    let id = UUID()
    let sender: HowChatSender
    var text: String
    var isStreaming: Bool = false
}

struct HowChatChoice: Identifiable {
    let id = UUID()
    let label: String
}
