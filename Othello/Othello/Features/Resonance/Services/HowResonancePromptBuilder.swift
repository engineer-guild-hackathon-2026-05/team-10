import Foundation

/// 1回目の「決めうち」問いかけを生成する（FR-RES-02）。
/// LLM を呼ばず、ピーク地点について固定文で問う。2回目以降は LLM（ChatAPIClient）に委ねる。
enum HowResonancePromptBuilder {
    struct Prompt: Equatable {
        let question: String
        let choices: [String]
    }

    /// ピーク地点起点の固定問いかけ。peak が nil の場合は汎用文。
    static func firstPrompt(peak: PeakMoment?) -> Prompt {
        guard let peak else {
            return Prompt(
                question: "この曲で、ふと身体が動いた瞬間はありましたか？",
                choices: ["あった気がする", "わからない", "全体的にノっていた"]
            )
        }

        return Prompt(
            question: "\(peak.formattedTime) あたりで、一番大きく動いていました。ここ、どうでしたか？",
            choices: [
                "リズムに乗っていた",
                "歌詞が刺さった",
                "サビの盛り上がり",
                "気づいたら動いていた"
            ]
        )
    }
}
