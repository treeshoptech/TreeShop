//
//  AuthService.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData
import CryptoKit

@Observable
final class AuthService {
    private let modelContext: ModelContext
    private(set) var currentUser: User?
    private(set) var isAuthenticated = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCurrentUser()
    }

    // MARK: - Authentication

    func signUp(email: String, password: String, name: String) async throws {
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            throw AuthError.invalidInput
        }

        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.passwordTooShort
        }

        // Check if user already exists
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        let existingUsers = try modelContext.fetch(descriptor)

        guard existingUsers.isEmpty else {
            throw AuthError.userAlreadyExists
        }

        // Hash password
        let passwordHash = hashPassword(password)

        // Create new user
        let newUser = User(email: email, passwordHash: passwordHash, name: name)
        modelContext.insert(newUser)
        try modelContext.save()

        // Set as current user
        currentUser = newUser
        isAuthenticated = true
        saveCurrentUserId(newUser.id)
    }

    func login(email: String, password: String) async throws {
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidInput
        }

        // Find user
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.email == email }
        )
        let users = try modelContext.fetch(descriptor)

        guard let user = users.first else {
            throw AuthError.invalidCredentials
        }

        // Verify password
        let passwordHash = hashPassword(password)
        guard user.passwordHash == passwordHash else {
            throw AuthError.invalidCredentials
        }

        // Update last login
        user.lastLoginAt = Date()
        try modelContext.save()

        // Set as current user
        currentUser = user
        isAuthenticated = true
        saveCurrentUserId(user.id)
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
        clearCurrentUserId()
    }

    // MARK: - Private Helpers

    private func loadCurrentUser() {
        guard let userId = getCurrentUserId() else { return }

        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == userId }
        )

        if let user = try? modelContext.fetch(descriptor).first {
            currentUser = user
            isAuthenticated = true
        }
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
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
    case invalidInput
    case invalidEmail
    case passwordTooShort
    case userAlreadyExists
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please fill in all fields"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 8 characters"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}
