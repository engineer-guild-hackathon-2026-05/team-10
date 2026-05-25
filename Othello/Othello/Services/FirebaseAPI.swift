import FirebaseAuth
import FirebaseFirestore
import Foundation

enum FirebaseAPIError: Error {
    case missingDocumentID
    case documentNotFound
    case missingEmail
}

final class FirebaseAPI {
    static let shared = FirebaseAPI()

    private let firestore: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.firestore = firestore
    }

    func createHowCard(_ howCard: HowCardComment) async throws -> String {
        let document = howCard.documentID.map { howCardsCollection.document($0) } ?? howCardsCollection.document()
        var persistedHowCard = howCard
        persistedHowCard.documentID = document.documentID
        try await setData(from: persistedHowCard, at: document, merge: false)
        return document.documentID
    }

    func updateHowCard(_ howCard: HowCardComment) async throws {
        guard let documentID = howCard.documentID else {
            throw FirebaseAPIError.missingDocumentID
        }

        try await setData(from: howCard, at: howCardsCollection.document(documentID), merge: true)
    }

    func fetchHowCard(id: String) async throws -> HowCardComment {
        let snapshot = try await howCardsCollection.document(id).getDocument()
        guard snapshot.exists else {
            throw FirebaseAPIError.documentNotFound
        }

        return try snapshot.data(as: HowCardComment.self)
    }

    func fetchHowCards(songID: String, limit: Int = 50) async throws -> [HowCardComment] {
        let query = howCardsCollection
            .whereField(FieldKey.songID, isEqualTo: songID)
            .limit(to: limit)
        let snapshot = try await getDocuments(for: query)
        return try snapshot.documents.map { try $0.data(as: HowCardComment.self) }
    }

    func incrementGoods(cardID: String) async throws {
        try await updateData(
            [FieldKey.goods: FieldValue.increment(Int64(1))],
            at: howCardsCollection.document(cardID)
        )
    }

    func upsertUser(_ user: FirestoreUser) async throws {
        let documentID = user.documentID ?? user.userID
        try await setData(from: user, at: usersCollection.document(documentID), merge: true)
    }

    func fetchUser(uid: String) async throws -> FirestoreUser {
        let snapshot = try await usersCollection.document(uid).getDocument()
        guard snapshot.exists else {
            throw FirebaseAPIError.documentNotFound
        }

        return try snapshot.data(as: FirestoreUser.self)
    }

    func createUserDocument(from user: User) async throws {
        guard let email = user.email, !email.isEmpty else {
            throw FirebaseAPIError.missingEmail
        }

        let now = Date()
        let firestoreUser = FirestoreUser(
            documentID: user.uid,
            userID: user.uid,
            email: email,
            displayName: user.displayName,
            createdAt: now,
            updatedAt: now
        )
        try await upsertUser(firestoreUser)
    }

    private var howCardsCollection: CollectionReference {
        firestore.collection(CollectionName.howCards)
    }

    private var usersCollection: CollectionReference {
        firestore.collection(CollectionName.users)
    }

    private func setData<T: Encodable>(
        from value: T,
        at document: DocumentReference,
        merge: Bool
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try document.setData(from: value, merge: merge) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func updateData(_ data: [AnyHashable: Any], at document: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            document.updateData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func getDocuments(for query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<QuerySnapshot, Error>) in
            query.getDocuments { snapshot, error in
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
}

private enum CollectionName {
    static let howCards = "how-cards"
    static let users = "users"
}

private enum FieldKey {
    static let goods = "goods"
    static let songID = "song_id"
}
