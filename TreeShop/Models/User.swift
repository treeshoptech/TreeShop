//
//  User.swift
//  TreeShop
//
//  Created on 9/30/25.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var passwordHash: String
    var name: String
    var createdAt: Date
    var lastLoginAt: Date

    init(email: String, passwordHash: String, name: String) {
        self.id = UUID()
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
        self.createdAt = Date()
        self.lastLoginAt = Date()
    }
}
