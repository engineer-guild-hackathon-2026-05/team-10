import Foundation

enum ClipTab: String, CaseIterable, Identifiable {
    case playback = "再生"
    case clip = "切り抜き"
    var id: Self { self }
}
