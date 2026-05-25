import SwiftUI

struct Artist: Identifiable {
    let id: UUID
    let name: String
    let listeningCount: String
    let tag: String
    let gradientColors: [Color]
    let songs: [Song]
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
                listeningCount: "12.4K listening",
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
                listeningCount: "8.2K listening",
                tag: "雨の朝",
                gradientColors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.05, green: 0.15, blue: 0.4)],
                songs: [
                    Song(id: UUID(), title: "Midnight Bloom", artistName: "Aimer", gradientColors: [Color(red: 0.1, green: 0.3, blue: 0.6), Color(red: 0.05, green: 0.15, blue: 0.4)], durationSeconds: 278),
                    Song(id: UUID(), title: "蝶々結び", artistName: "Aimer", gradientColors: [Color(red: 0.15, green: 0.25, blue: 0.55), Color(red: 0.08, green: 0.12, blue: 0.35)], durationSeconds: 312),
                    Song(id: UUID(), title: "ref:rain", artistName: "Aimer", gradientColors: [Color(red: 0.2, green: 0.35, blue: 0.65), Color(red: 0.1, green: 0.2, blue: 0.45)], durationSeconds: 256)
                ]
            ),
            Artist(
                id: UUID(),
                name: "King Gnu",
                listeningCount: "5.1K listening",
                tag: "Live now",
                gradientColors: [Color(red: 0.1, green: 0.55, blue: 0.5), Color(red: 0.05, green: 0.3, blue: 0.4)],
                songs: [
                    Song(id: UUID(), title: "白日", artistName: "King Gnu", gradientColors: [Color(red: 0.1, green: 0.55, blue: 0.5), Color(red: 0.05, green: 0.3, blue: 0.4)], durationSeconds: 294),
                    Song(id: UUID(), title: "Teenager Forever", artistName: "King Gnu", gradientColors: [Color(red: 0.15, green: 0.6, blue: 0.45), Color(red: 0.08, green: 0.35, blue: 0.35)], durationSeconds: 267),
                    Song(id: UUID(), title: "三文小説", artistName: "King Gnu", gradientColors: [Color(red: 0.05, green: 0.45, blue: 0.55), Color(red: 0.03, green: 0.25, blue: 0.38)], durationSeconds: 283)
                ]
            ),
            Artist(
                id: UUID(),
                name: "YOASOBI",
                listeningCount: "32.7K listening",
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
                listeningCount: "18.9K listening",
                tag: "Heavy rotation",
                gradientColors: [Color(red: 0.55, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.05)],
                songs: [
                    Song(id: UUID(), title: "感電", artistName: "米津玄師", gradientColors: [Color(red: 0.55, green: 0.1, blue: 0.1), Color(red: 0.15, green: 0.05, blue: 0.05)], durationSeconds: 268),
                    Song(id: UUID(), title: "Lemon", artistName: "米津玄師", gradientColors: [Color(red: 0.6, green: 0.15, blue: 0.08), Color(red: 0.2, green: 0.08, blue: 0.05)], durationSeconds: 266),
                    Song(id: UUID(), title: "Pale Blue", artistName: "米津玄師", gradientColors: [Color(red: 0.1, green: 0.25, blue: 0.5), Color(red: 0.05, green: 0.1, blue: 0.3)], durationSeconds: 297),
                    Song(id: UUID(), title: "打上花火", artistName: "米津玄師", gradientColors: [Color(red: 0.45, green: 0.08, blue: 0.15), Color(red: 0.1, green: 0.04, blue: 0.08)], durationSeconds: 276)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Vaundy",
                listeningCount: "24.1K listening",
                tag: "New album",
                gradientColors: [Color(red: 0.85, green: 0.25, blue: 0.6), Color(red: 0.5, green: 0.1, blue: 0.45)],
                songs: [
                    Song(id: UUID(), title: "Soda Pop", artistName: "Vaundy", gradientColors: [Color(red: 0.85, green: 0.25, blue: 0.6), Color(red: 0.5, green: 0.1, blue: 0.45)], durationSeconds: 228),
                    Song(id: UUID(), title: "怪獣の花唄", artistName: "Vaundy", gradientColors: [Color(red: 0.7, green: 0.2, blue: 0.65), Color(red: 0.4, green: 0.08, blue: 0.4)], durationSeconds: 262),
                    Song(id: UUID(), title: "napori", artistName: "Vaundy", gradientColors: [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 0.6, green: 0.15, blue: 0.35)], durationSeconds: 195)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Mrs. GREEN APPLE",
                listeningCount: "21.5K listening",
                tag: "人気上昇中",
                gradientColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.2)],
                songs: [
                    Song(id: UUID(), title: "ライラック", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.5)], durationSeconds: 272),
                    Song(id: UUID(), title: "青と夏", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.15, green: 0.55, blue: 0.35), Color(red: 0.05, green: 0.3, blue: 0.2)], durationSeconds: 248),
                    Song(id: UUID(), title: "点描の唄", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.3, green: 0.5, blue: 0.25), Color(red: 0.12, green: 0.28, blue: 0.12)], durationSeconds: 301),
                    Song(id: UUID(), title: "StaRt", artistName: "Mrs. GREEN APPLE", gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.08, green: 0.35, blue: 0.22)], durationSeconds: 215)
                ]
            ),
            Artist(
                id: UUID(),
                name: "King & Prince",
                listeningCount: "6.3K listening",
                tag: "Pop",
                gradientColors: [Color(red: 0.6, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.15, blue: 0.55)],
                songs: [
                    Song(id: UUID(), title: "ツキヨミ", artistName: "King & Prince", gradientColors: [Color(red: 0.6, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.15, blue: 0.55)], durationSeconds: 234),
                    Song(id: UUID(), title: "Magic Touch", artistName: "King & Prince", gradientColors: [Color(red: 0.7, green: 0.4, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.5)], durationSeconds: 218),
                    Song(id: UUID(), title: "ichiban", artistName: "King & Prince", gradientColors: [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.3, green: 0.12, blue: 0.6)], durationSeconds: 252)
                ]
            ),
            Artist(
                id: UUID(),
                name: "Official髭男dism",
                listeningCount: "14.0K listening",
                tag: "Trending",
                gradientColors: [Color(red: 0.85, green: 0.5, blue: 0.15), Color(red: 0.55, green: 0.25, blue: 0.05)],
                songs: [
                    Song(id: UUID(), title: "Pretender", artistName: "Official髭男dism", gradientColors: [Color(red: 0.85, green: 0.5, blue: 0.15), Color(red: 0.55, green: 0.25, blue: 0.05)], durationSeconds: 272),
                    Song(id: UUID(), title: "I LOVE...", artistName: "Official髭男dism", gradientColors: [Color(red: 0.75, green: 0.4, blue: 0.2), Color(red: 0.45, green: 0.18, blue: 0.08)], durationSeconds: 284),
                    Song(id: UUID(), title: "Subtitle", artistName: "Official髭男dism", gradientColors: [Color(red: 0.9, green: 0.55, blue: 0.1), Color(red: 0.6, green: 0.3, blue: 0.05)], durationSeconds: 260),
                    Song(id: UUID(), title: "Cry Baby", artistName: "Official髭男dism", gradientColors: [Color(red: 0.8, green: 0.45, blue: 0.25), Color(red: 0.5, green: 0.2, blue: 0.1)], durationSeconds: 239)
                ]
            )
        ]
    }
}
