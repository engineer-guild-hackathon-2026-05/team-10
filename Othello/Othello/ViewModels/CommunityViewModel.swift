import Foundation
import SwiftUI
import Combine

// FR-COMM-01〜04: コミュニティ画面のViewModel（モックデータ）
@MainActor
final class CommunityViewModel: ObservableObject {

    // MARK: - My How

    struct MyHowCard: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let tag: HowTag
        let trackTitle: String
        let trackArtist: String
        let createdAt: String
    }

    let myHowCards: [MyHowCard] = [
        MyHowCard(
            title: "深夜に染み込む孤独感",
            description: "歌詞の映像喚起力に完全に引き込まれた。コンビニの灯りの描写が刺さりすぎた。",
            tag: .hit,
            trackTitle: "感電",
            trackArtist: "米津玄師",
            createdAt: "2日前"
        ),
        MyHowCard(
            title: "身体が勝手にリズムを刻む",
            description: "イントロから頭が動いてしまう。ビートとベースラインの絡みが最高。",
            tag: .groove,
            trackTitle: "感電",
            trackArtist: "米津玄師",
            createdAt: "5日前"
        ),
    ]

    // MARK: - Community Listeners

    struct CommunityListener: Identifiable {
        let id = UUID()
        let name: String
        let howTag: HowTag
        let howTitle: String
        let trackTitle: String
        let mutualCount: Int
    }

    let allListeners: [CommunityListener] = [
        CommunityListener(name: "haru___m", howTag: .hit, howTitle: "この歌詞で泣いた", trackTitle: "感電", mutualCount: 3),
        CommunityListener(name: "nocturnalvibes", howTag: .chill, howTitle: "深夜ドライブに最高", trackTitle: "夜に駆ける", mutualCount: 1),
        CommunityListener(name: "groove_seeker", howTag: .groove, howTitle: "ビートに乗れて最高", trackTitle: "感電", mutualCount: 5),
        CommunityListener(name: "lyric_nerd", howTag: .immersion, howTitle: "歌詞の世界に入り込む", trackTitle: "Lemon", mutualCount: 2),
        CommunityListener(name: "afterglow99", howTag: .afterglow, howTitle: "余韻が抜けない", trackTitle: "感電", mutualCount: 4),
        CommunityListener(name: "hype_machine", howTag: .hype, howTitle: "テンションが爆上がり", trackTitle: "打上花火", mutualCount: 1),
        CommunityListener(name: "still_water_v", howTag: .chill, howTitle: "心が落ち着く", trackTitle: "感電", mutualCount: 2),
        CommunityListener(name: "kokoro_kizamu", howTag: .hit, howTitle: "この一節が全部", trackTitle: "愛にできることはまだあるかい", mutualCount: 6),
    ]

    // MARK: - Popular Tracks by How

    struct HowTrack: Identifiable {
        let id = UUID()
        let trackTitle: String
        let trackArtist: String
        let howTag: HowTag
        let howCount: Int
    }

    let popularTracks: [HowTrack] = [
        HowTrack(trackTitle: "感電", trackArtist: "米津玄師", howTag: .groove, howCount: 341),
        HowTrack(trackTitle: "夜に駆ける", trackArtist: "YOASOBI", howTag: .hit, howCount: 289),
        HowTrack(trackTitle: "Lemon", trackArtist: "米津玄師", howTag: .afterglow, howCount: 214),
        HowTrack(trackTitle: "打上花火", trackArtist: "DAOKO×米津玄師", howTag: .hype, howCount: 198),
        HowTrack(trackTitle: "愛にできることはまだあるかい", trackArtist: "RADWIMPS", howTag: .chill, howCount: 176),
    ]

    // MARK: - Filter

    @Published var selectedTag: HowTag? = nil

    var filteredListeners: [CommunityListener] {
        guard let tag = selectedTag else { return allListeners }
        return allListeners.filter { $0.howTag == tag }
    }

    var filteredTracks: [HowTrack] {
        guard let tag = selectedTag else { return popularTracks }
        return popularTracks.filter { $0.howTag == tag }
    }

    // FR-COMM-03: 人気Howタグ（全リスナーの集計）
    var popularTags: [(HowTag, Int)] {
        var counts: [HowTag: Int] = [:]
        for listener in allListeners {
            counts[listener.howTag, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }
}
