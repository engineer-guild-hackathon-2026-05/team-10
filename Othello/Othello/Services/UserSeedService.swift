import FirebaseFirestore
import Foundation

enum UserSeedService {
    private static let collectionName = "users"

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

        var profiles: [UserProfile] = []
        for seed in seeds {
            let profile = try await upsertSeedUser(seed)
            profiles.append(profile)
        }
        return profiles
    }

    static func fetchUsers(ids: [String]) async throws -> [UserProfile] {
        var profiles: [UserProfile] = []
        for userID in uniqueUserIDs(from: ids) {
            let ref = Firestore.firestore().collection(collectionName).document(userID)
            let snapshot = try await getDocument(ref)
            guard snapshot.exists, let profile = userProfile(from: snapshot) else {
                continue
            }
            profiles.append(profile)
        }
        return profiles
    }

    static func seedProfiles(for howCards: [HowCardComment]) -> [UserSeedProfile] {
        uniqueUserIDs(from: howCards.map(\.userID)).enumerated().map { index, userID in
            UserSeedProfile(
                userID: userID,
                email: nil,
                displayName: displayName(for: index)
            )
        }
    }

    private static func upsertSeedUser(_ seed: UserSeedProfile) async throws -> UserProfile {
        let ref = Firestore.firestore().collection(collectionName).document(seed.userID)
        let snapshot = try await getDocument(ref)
        let existingData = snapshot.data() ?? [:]

        var data: [String: Any] = [
            "user_id": seed.userID,
            "updated_at": FieldValue.serverTimestamp()
        ]

        if !snapshot.exists || stringValue(existingData["display_name"]) == nil {
            data["display_name"] = seed.displayName
        }

        if let email = seed.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
           !snapshot.exists || stringValue(existingData["email"]) == nil {
            data["email"] = email
        } else if !snapshot.exists {
            data["email"] = NSNull()
        }

        if !snapshot.exists || existingData["created_at"] == nil {
            data["created_at"] = FieldValue.serverTimestamp()
        }

        try await setData(data, for: ref)
        let refreshedSnapshot = try await getDocument(ref)

        if let profile = userProfile(from: refreshedSnapshot) {
            return profile
        }

        return UserProfile(
            id: seed.userID,
            userID: seed.userID,
            email: seed.email,
            displayName: seed.displayName
        )
    }

    private static func getDocument(_ ref: DocumentReference) async throws -> DocumentSnapshot {
        try await withCheckedThrowingContinuation { continuation in
            ref.getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: FirebaseAPIError.documentNotFound)
                }
            }
        }
    }

    private static func setData(_ data: [String: Any], for ref: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.setData(data, merge: true) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private static func userProfile(from snapshot: DocumentSnapshot) -> UserProfile? {
        guard let data = snapshot.data() else {
            return nil
        }

        let userID = stringValue(data["user_id"]) ?? snapshot.documentID
        return UserProfile(
            id: snapshot.documentID,
            userID: userID,
            email: stringValue(data["email"]),
            displayName: stringValue(data["display_name"]) ?? stringValue(data["displayName"]),
            createdAt: timestampString(from: data["created_at"] ?? data["createdAt"]),
            updatedAt: timestampString(from: data["updated_at"] ?? data["updatedAt"])
        )
    }

    private static func uniqueUserIDs(from userIDs: [String]) -> [String] {
        var seen = Set<String>()
        return userIDs
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
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

    private static func stringValue(_ value: Any?) -> String? {
        guard let string = value as? String else {
            return nil
        }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func timestampString(from value: Any?) -> String? {
        if let timestamp = value as? Timestamp {
            return ISO8601DateFormatter().string(from: timestamp.dateValue())
        }

        if let date = value as? Date {
            return ISO8601DateFormatter().string(from: date)
        }

        return stringValue(value)
    }
}
