import Foundation
import SwiftUI

struct Artist: Identifiable {
    let id: UUID
    let name: String
    let listeningCount: String
    let tag: String
    let gradientColors: [Color]
    let artworkURL: URL?
    let songs: [Song]

    init(
        id: UUID,
        name: String,
        listeningCount: String,
        tag: String,
        gradientColors: [Color],
        artworkURL: URL? = nil,
        songs: [Song]
    ) {
        self.id = id
        self.name = name
        self.listeningCount = listeningCount
        self.tag = tag
        self.gradientColors = gradientColors
        self.artworkURL = artworkURL
        self.songs = songs
    }
}

extension Artist: Hashable {
    static func == (lhs: Artist, rhs: Artist) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Artist {
    static let catalog: [Artist] = makeCatalog()

    private static func makeCatalog() -> [Artist] {
        [
            Artist(
                id: UUID(),
                name: "ここのっか",
                listeningCount: "1.2万回の共鳴",
                tag: "最近聴いた",
                gradientColors: [Color(red: 0.95, green: 0.55, blue: 0.3), Color(red: 0.85, green: 0.35, blue: 0.5)],
                songs: [
                    Song(id: UUID(), title: "ここのっか", artistName: "ここのっか", gradientColors: [Color(red: 0.95, green: 0.55, blue: 0.3), Color(red: 0.85, green: 0.35, blue: 0.5)], durationSeconds: 245),
                    Song(id: UUID(), title: "一筋", artistName: "ここのっか", gradientColors: [Color(red: 0.9, green: 0.4, blue: 0.4), Color(red: 0.7, green: 0.2, blue: 0.3)], durationSeconds: 218),
                    Song(id: UUID(), title: "春は溶けて", artistName: "ここのっか", gradientColors: [Color(red: 0.8, green: 0.6, blue: 0.3), Color(red: 0.6, green: 0.3, blue: 0.2)], durationSeconds: 232),
                    Song(id: UUID(), title: "ふたつ", artistName: "ここのっか", gradientColors: [Color(red: 0.7, green: 0.45, blue: 0.6), Color(red: 0.5, green: 0.25, blue: 0.4)], durationSeconds: 205)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Aimer",
                listeningCount: "8,200件の反応",
                tag: "雨の朝",
                gradientColors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.05, green: 0.15, blue: 0.4)],
                songs: [
                    Song(id: UUID(), title: "残響散歌", artistName: "Aimer", gradientColors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.05, green: 0.15, blue: 0.4)], durationSeconds: 278),
                    Song(id: UUID(), title: "蝶々結び", artistName: "Aimer", gradientColors: [Color(red: 0.15, green: 0.25, blue: 0.55), Color(red: 0.08, green: 0.12, blue: 0.35)], durationSeconds: 312),
                    Song(id: UUID(), title: "カタオモイ", artistName: "Aimer", gradientColors: [Color(red: 0.2, green: 0.35, blue: 0.65), Color(red: 0.1, green: 0.2, blue: 0.45)], durationSeconds: 256)
                ]
            ),
            Artist(
                id: UUID(),
                name: "King Gnu",
                listeningCount: "5,100件の反応",
                tag: "ライブで話題",
                gradientColors: [Color(red: 0.1, green: 0.55, blue: 0.5), Color(red: 0.05, green: 0.3, blue: 0.4)],
                songs: [
                    Song(id: UUID(), title: "白日", artistName: "King Gnu", gradientColors: [Color(red: 0.1, green: 0.55, blue: 0.5), Color(red: 0.05, green: 0.3, blue: 0.4)], durationSeconds: 294),
                    Song(id: UUID(), title: "逆夢", artistName: "King Gnu", gradientColors: [Color(red: 0.15, green: 0.6, blue: 0.45), Color(red: 0.08, green: 0.35, blue: 0.35)], durationSeconds: 267),
                    Song(id: UUID(), title: "三文小説", artistName: "King Gnu", gradientColors: [Color(red: 0.05, green: 0.45, blue: 0.55), Color(red: 0.03, green: 0.25, blue: 0.38)], durationSeconds: 283)
                ]
            ),
            Artist(
                id: UUID(),
                name: "YOASOBI",
                listeningCount: "3.2万件の反応",
                tag: "おすすめ",
                gradientColors: [Color(red: 0.75, green: 0.2, blue: 0.55), Color(red: 0.45, green: 0.1, blue: 0.35)],
                songs: [
                    Song(id: UUID(), title: "夜に駆ける", artistName: "YOASOBI", gradientColors: [Color(red: 0.75, green: 0.2, blue: 0.55), Color(red: 0.45, green: 0.1, blue: 0.35)], durationSeconds: 256),
                    Song(id: UUID(), title: "群青", artistName: "YOASOBI", gradientColors: [Color(red: 0.6, green: 0.15, blue: 0.6), Color(red: 0.35, green: 0.08, blue: 0.4)], durationSeconds: 324),
                    Song(id: UUID(), title: "アイドル", artistName: "YOASOBI", gradientColors: [Color(red: 0.85, green: 0.25, blue: 0.45), Color(red: 0.55, green: 0.12, blue: 0.3)], durationSeconds: 210),
                    Song(id: UUID(), title: "怪物", artistName: "YOASOBI", gradientColors: [Color(red: 0.7, green: 0.1, blue: 0.5), Color(red: 0.4, green: 0.05, blue: 0.3)], durationSeconds: 238)
                ]
            ),
            Artist(
                id: UUID(),
                name: "米津玄師",
                listeningCount: "1.8万件の反応",
                tag: "ヘビロテ中",
                gradientColors: [Color(red: 0.55, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.05)],
                songs: [
                    Song(id: UUID(), title: "感電", artistName: "米津玄師", gradientColors: [Color(red: 0.55, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.05)], durationSeconds: 268),
                    Song(id: UUID(), title: "馬と鹿", artistName: "米津玄師", gradientColors: [Color(red: 0.6, green: 0.15, blue: 0.08), Color(red: 0.2, green: 0.08, blue: 0.05)], durationSeconds: 266),
                    Song(id: UUID(), title: "地球儀", artistName: "米津玄師", gradientColors: [Color(red: 0.1, green: 0.25, blue: 0.5), Color(red: 0.05, green: 0.1, blue: 0.3)], durationSeconds: 297),
                    Song(id: UUID(), title: "打上花火", artistName: "米津玄師", gradientColors: [Color(red: 0.45, green: 0.08, blue: 0.15), Color(red: 0.1, green: 0.04, blue: 0.08)], durationSeconds: 276)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Vaundy",
                listeningCount: "2.4万件の反応",
                tag: "新着",
                gradientColors: [Color(red: 0.85, green: 0.25, blue: 0.6), Color(red: 0.5, green: 0.1, blue: 0.45)],
                songs: [
                    Song(id: UUID(), title: "踊り子", artistName: "Vaundy", gradientColors: [Color(red: 0.85, green: 0.25, blue: 0.6), Color(red: 0.5, green: 0.1, blue: 0.45)], durationSeconds: 228),
                    Song(id: UUID(), title: "怪獣の花唄", artistName: "Vaundy", gradientColors: [Color(red: 0.7, green: 0.2, blue: 0.65), Color(red: 0.4, green: 0.08, blue: 0.4)], durationSeconds: 262),
                    Song(id: UUID(), title: "不可幸力", artistName: "Vaundy", gradientColors: [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 0.6, green: 0.15, blue: 0.35)], durationSeconds: 195)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Mrs. GREEN APPLE",
                listeningCount: "2.1万件の反応",
                tag: "人気上昇中",
                gradientColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.2)],
                songs: [
                    Song(id: UUID(), title: "ライラック", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.5)], durationSeconds: 272),
                    Song(id: UUID(), title: "青と夏", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.2)], durationSeconds: 248),
                    Song(id: UUID(), title: "点描の唄", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.3, green: 0.5, blue: 0.25), Color(red: 0.12, green: 0.28, blue: 0.12)], durationSeconds: 301),
                    Song(id: UUID(), title: "僕のこと", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.08, green: 0.35, blue: 0.22)], durationSeconds: 215)
                ]
            ),
            Artist(
                id: UUID(),
                name: "King & Prince",
                listeningCount: "6,300件の反応",
                tag: "ポップ",
                gradientColors: [Color(red: 0.6, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.15, blue: 0.55)],
                songs: [
                    Song(id: UUID(), title: "ツキヨミ", artistName: "King & Prince", gradientColors: [Color(red: 0.6, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.15, blue: 0.55)], durationSeconds: 234),
                    Song(id: UUID(), title: "シンデレラガール", artistName: "King & Prince", gradientColors: [Color(red: 0.7, green: 0.4, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.5)], durationSeconds: 218),
                    Song(id: UUID(), title: "なにもの", artistName: "King & Prince", gradientColors: [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.12, blue: 0.6)], durationSeconds: 252)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Official髭男dism",
                listeningCount: "1.4万件の反応",
                tag: "話題",
                gradientColors: [Color(red: 0.85, green: 0.5, blue: 0.15), Color(red: 0.55, green: 0.25, blue: 0.05)],
                songs: [
                    Song(id: UUID(), title: "宿命", artistName: "Official髭男dism", gradientColors: [Color(red: 0.85, green: 0.5, blue: 0.15), Color(red: 0.55, green: 0.25, blue: 0.05)], durationSeconds: 272),
                    Song(id: UUID(), title: "ミックスナッツ", artistName: "Official髭男dism", gradientColors: [Color(red: 0.75, green: 0.4, blue: 0.2), Color(red: 0.45, green: 0.18, blue: 0.08)], durationSeconds: 284),
                    Song(id: UUID(), title: "ノーダウト", artistName: "Official髭男dism", gradientColors: [Color(red: 0.9, green: 0.55, blue: 0.1), Color(red: 0.6, green: 0.3, blue: 0.05)], durationSeconds: 260),
                    Song(id: UUID(), title: "異端なスター", artistName: "Official髭男dism", gradientColors: [Color(red: 0.8, green: 0.45, blue: 0.25), Color(red: 0.5, green: 0.2, blue: 0.1)], durationSeconds: 239)
                ]
            )
        ]
    }
}
