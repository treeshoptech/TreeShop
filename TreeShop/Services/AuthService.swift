//
//  AuthService.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData
import AuthenticationServices

@Observable
final class AuthService {
    private let modelContext: ModelContext
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    // MARK: - Sign in with Apple

    func handleSignInWithApple(authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredentials
        }

        let appleUserID = appleIDCredential.user
        let email = appleIDCredential.email ?? "\(appleUserID)@privaterelay.appleid.com"
        let fullName = appleIDCredential.fullName
        let name = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        // Check if user exists
        let descriptor = FetchDescriptor<User>()
        let allUsers = try modelContext.fetch(descriptor)

        if let existingUser = allUsers.first(where: { $0.appleUserID == appleUserID }) {
            // Existing user - log in
            existingUser.lastLoginAt = Date()
            try modelContext.save()

            currentUser = existingUser
            isAuthenticated = true
            saveCurrentUserId(existingUser.id)
        } else {
            // New user - sign up
            let newUser = User(
                email: email,
                passwordHash: "", // Not needed with Apple Sign In
                name: name.isEmpty ? "TreeShop User" : name
            )
            newUser.appleUserID = appleUserID

            modelContext.insert(newUser)
            try modelContext.save()

            currentUser = newUser
            isAuthenticated = true
            saveCurrentUserId(newUser.id)
        }
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        clearCurrentUserId()
    }

    // MARK: - Private Helpers

    private func loadCurrentUser() {
        guard let userId = getCurrentUserId() else { return }

        let descriptor = FetchDescriptor<User>()
        let allUsers = (try? modelContext.fetch(descriptor)) ?? []

        if let user = allUsers.first(where: { $0.id == userId }) {
            currentUser = user
            isAuthenticated = true
        }
    }

    // MARK: - UserDefaults Persistence

    private func saveCurrentUserId(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: "currentUserId")
    }

    private func getCurrentUserId() -> UUID? {
        guard let idString = UserDefaults.standard.string(forKey: "currentUserId") else {
            return nil
        }
        return UUID(uuidString: idString)
    }

    private func clearCurrentUserId() {
        UserDefaults.standard.removeObject(forKey: "currentUserId")
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case signInFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Sign in failed"
        case .signInFailed:
            return "Unable to sign in with Apple"
        }
    }
}
