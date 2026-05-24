import Foundation

enum LyricsLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable(String)
    case failed(String)

    var message: String? {
        switch self {
        case .unavailable(let message), .failed(let message):
            return message
        case .idle, .loading, .loaded:
            return nil
        }
    }
}
