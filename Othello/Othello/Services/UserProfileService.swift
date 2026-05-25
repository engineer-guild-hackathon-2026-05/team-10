import FirebaseAuth
import FirebaseFirestore
import Foundation

enum UserProfileService {
    private static let collectionName = "users"

    static func fetchUsers(ids: [String]) async throws -> [UserProfile] {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            return []
        }

        var profiles: [UserProfile] = []
        for userID in uniqueUserIDs(from: ids).filter({ $0 == currentUserID }) {
            let ref = Firestore.firestore().collection(collectionName).document(userID)
            let snapshot = try await getDocument(ref)
            guard snapshot.exists, let profile = userProfile(from: snapshot) else {
                continue
            }
            profiles.append(profile)
        }
        return profiles
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
