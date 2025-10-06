//
//  AppUser.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation

struct AppUser: Codable, Identifiable {
    let id: String
    let authUserId: String
    let emailSnapshot: String?
    let name: String?
    let username: String?
    let birthDate: Date?
    let avatarUrl: String?
    let roles: [String]
    let lastLoginAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case emailSnapshot = "email_snapshot"
        case name
        case username
        case birthDate = "birth_date"
        case avatarUrl = "avatar_url"
        case roles
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Helpers
extension AppUser {
    var displayName: String {
        name ?? username ?? "User"
    }
    
    var formattedBirthDate: String? {
        guard let birthDate = birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: birthDate)
    }
    
    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
}

