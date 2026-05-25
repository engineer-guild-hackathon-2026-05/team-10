import Foundation

enum UserSeedService {
    private static let displayNames = [
        "みなと",
        "あかり",
        "そうた",
        "ゆい",
        "はる",
        "りん",
        "なお",
        "かなた",
        "ひまり",
        "いつき",
        "しおり",
        "つむぎ",
        "れん",
        "あおい",
        "まこと",
        "こはる"
    ]

    @discardableResult
    static func seedUsersForExistingHowCards(limit: Int = 250) async throws -> [UserProfile] {
        let howCards = try await FirebaseAPI.shared.fetchHowCards(limit: limit)
        return try await seedUsers(for: howCards)
    }

    @discardableResult
    static func seedUsers(for howCards: [HowCardComment]) async throws -> [UserProfile] {
        let seeds = seedProfiles(for: howCards)
        guard !seeds.isEmpty else {
            return []
        }

        return try await FirebaseAPI.shared.seedUsers(seeds)
    }

    static func seedProfiles(for howCards: [HowCardComment]) -> [UserSeedProfile] {
        uniqueUserIDs(from: howCards).enumerated().map { index, userID in
            UserSeedProfile(
                userID: userID,
                email: nil,
                displayName: displayName(for: index)
            )
        }
    }

    private static func uniqueUserIDs(from howCards: [HowCardComment]) -> [String] {
        var seen = Set<String>()
        return howCards
            .map { $0.userID.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
            .filter { userID in
                guard !seen.contains(userID) else { return false }
                seen.insert(userID)
                return true
            }
    }

    private static func displayName(for index: Int) -> String {
        let baseName = displayNames[index % displayNames.count]
        let round = index / displayNames.count
        guard round > 0 else {
            return baseName
        }
        return "\(baseName) \(round + 1)"
    }
}
