import Foundation

enum FirebaseAPIError: Error, LocalizedError {
    case missingBaseURL
    case notAuthenticated
    case missingDocumentID
    case documentNotFound
    case missingEmail
    case badServerResponse(statusCode: Int, message: String?)
    case signOutRollbackFailed(original: Error, signOut: Error)

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:
            return "API_BASE_URL is not configured."
        case .notAuthenticated:
            return "Firebase user is not authenticated."
        case .missingDocumentID:
            return "Document ID is missing."
        case .documentNotFound:
            return "Document was not found."
        case .missingEmail:
            return "Email is missing."
        case .badServerResponse(let statusCode, let message):
            if let message, !message.isEmpty {
                return "HTTP \(statusCode): \(message)"
            }
            return "HTTP \(statusCode)"
        case .signOutRollbackFailed(let original, let signOut):
            return "Failed to create user profile: \(original.localizedDescription); sign-out rollback also failed: \(signOut.localizedDescription)"
        }
    }
}
