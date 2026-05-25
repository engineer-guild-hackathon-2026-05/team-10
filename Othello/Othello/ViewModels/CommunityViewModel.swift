import Combine
import FirebaseAuth
import Foundation
import SwiftUI

@MainActor
final class CommunityViewModel: ObservableObject {

    // MARK: - My How

    struct MyHowCard: Identifiable {
        let id: String
        let title: String
        let description: String
        let tag: HowTag
        let trackTitle: String
        let trackArtist: String
        let createdAt: String
    }

    // MARK: - Community Listeners

    struct CommunityListener: Identifiable {
        let id: String
        let name: String
        let howTag: HowTag
        let howTitle: String
        let trackTitle: String
        let mutualCount: Int
    }

    // MARK: - Popular Tracks by How

    struct HowTrack: Identifiable {
        let id: String
        let trackTitle: String
        let trackArtist: String
        let howTag: HowTag
        let howCount: Int
    }

    @Published var selectedTag: HowTag?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private var cards: [HowCardComment] = []
    @Published private var userProfilesByID: [String: UserProfile] = [:]

    private let songLookup: [String: (title: String, artistName: String)] = {
        var result: [String: (title: String, artistName: String)] = [:]
        for artist in Artist.catalog {
            for song in artist.songs {
                result[song.firestoreSongID] = (song.title, song.artistName)
            }
        }
        return result
    }()

    var myHowCards: [MyHowCard] {
        guard let uid = Auth.auth().currentUser?.uid else {
            return []
        }

        return cards
            .filter { $0.userID == uid }
            .map { card in
                let song = songMetadata(for: card.songID)
                return MyHowCard(
                    id: card.id,
                    title: card.comment,
                    description: card.comment,
                    tag: tag(for: card),
                    trackTitle: song.title,
                    trackArtist: song.artistName,
                    createdAt: "今"
                )
            }
    }

    var filteredListeners: [CommunityListener] {
        let currentUserID = Auth.auth().currentUser?.uid
        return cards
            .filter { $0.userID != currentUserID }
            .filter { card in
                guard let selectedTag else { return true }
                return tag(for: card) == selectedTag
            }
            .prefix(24)
            .map { card in
                let song = songMetadata(for: card.songID)
                return CommunityListener(
                    id: card.id,
                    name: displayName(from: card.userID),
                    howTag: tag(for: card),
                    howTitle: card.comment,
                    trackTitle: song.title,
                    mutualCount: min(max(card.goods / 40, 0), 8)
                )
            }
    }

    var filteredTracks: [HowTrack] {
        let filteredCards = cards.filter { card in
            guard let selectedTag else { return true }
            return tag(for: card) == selectedTag
        }

        let grouped = Dictionary(grouping: filteredCards, by: \.songID)
        return grouped.map { songID, cards in
            let song = songMetadata(for: songID)
            let tagCounts = Dictionary(grouping: cards.map(tag(for:)), by: { $0 })
                .mapValues(\.count)
            let dominantTag = tagCounts.max { $0.value < $1.value }?.key ?? .neutral
            return HowTrack(
                id: songID,
                trackTitle: song.title,
                trackArtist: song.artistName,
                howTag: dominantTag,
                howCount: cards.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.howCount == rhs.howCount {
                return lhs.trackTitle < rhs.trackTitle
            }
            return lhs.howCount > rhs.howCount
        }
        .prefix(10)
        .map { $0 }
    }

    var popularTags: [(HowTag, Int)] {
        let counts = Dictionary(grouping: cards.map(tag(for:)), by: { $0 })
            .mapValues(\.count)
        return counts.sorted { $0.value > $1.value }
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetchedCards = try await FirebaseAPI.shared.fetchHowCards(limit: 250)
            cards = fetchedCards
            await loadUserProfiles(for: fetchedCards)
        } catch {
            cards = []
            userProfilesByID = [:]
            errorMessage = "Howカードを取得できませんでした"
        }
    }

    private func loadUserProfiles(for cards: [HowCardComment]) async {
        let userIDs = uniqueUserIDs(from: cards)
        guard !userIDs.isEmpty else {
            userProfilesByID = [:]
            return
        }

        do {
            let seededUsers = try await UserSeedService.seedUsers(for: cards)
            userProfilesByID = profilesByID(seededUsers)
        } catch {
            do {
                let users = try await FirebaseAPI.shared.fetchUsers(ids: userIDs)
                userProfilesByID = profilesByID(users)
            } catch {
                userProfilesByID = [:]
            }
        }
    }

    private func songMetadata(for songID: String) -> (title: String, artistName: String) {
        songLookup[songID] ?? (songID, "unknown")
    }

    private func tag(for card: HowCardComment) -> HowTag {
        let comment = card.comment
        if comment.contains("雨")
            || comment.contains("沁み")
            || comment.contains("泣")
            || comment.contains("余韻")
            || comment.contains("落ち着く")
            || comment.contains("孤独") {
            return .chill
        }

        if comment.contains("リズム")
            || comment.contains("ビート")
            || comment.contains("ドライブ")
            || comment.contains("テンション")
            || comment.contains("BGM")
            || comment.contains("頭")
            || comment.contains("反則") {
            return .groove
        }

        return .neutral
    }

    private func displayName(from userID: String) -> String {
        if let displayName = userProfilesByID[userID]?.displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !displayName.isEmpty {
            return displayName
        }

        return "listener"
    }

    private func uniqueUserIDs(from cards: [HowCardComment]) -> [String] {
        var seen = Set<String>()
        return cards.compactMap { card in
            let userID = card.userID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !userID.isEmpty, !seen.contains(userID) else { return nil }
            seen.insert(userID)
            return userID
        }
    }

    private func profilesByID(_ profiles: [UserProfile]) -> [String: UserProfile] {
        Dictionary(uniqueKeysWithValues: profiles.map { ($0.userID, $0) })
    }
}
