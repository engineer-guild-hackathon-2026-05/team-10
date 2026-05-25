enum FirebaseAPIError: Error {
    case missingBaseURL
    case notAuthenticated
    case missingDocumentID
    case documentNotFound
    case missingEmail
    case badServerResponse(statusCode: Int)
    case signOutRollbackFailed(original: Error, signOut: Error)
}
