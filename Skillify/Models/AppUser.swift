//
//  AppUser.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation

struct AppUser: Codable, Identifiable {
    var id: String = ""
    var authUserId: String = ""
    var emailSnapshot: String? = nil
    var name: String? = nil
    var username: String? = nil
    var birthDate: Date? = nil
    var avatarUrl: String? = nil
    var roles: [String] = []
    var ownedSkills: [UserSkill] = []
    var desiredSkills: [UserSkill] = []
    var lastLoginAt: Date? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case emailSnapshot = "email_snapshot"
        case name
        case username
        case birthDate = "birth_date"
        case avatarUrl = "avatar_url"
        case roles
        case ownedSkills = "owned_skills"
        case desiredSkills = "desired_skills"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: String, authUserId: String, emailSnapshot: String? = nil, name: String? = nil, username: String? = nil, birthDate: Date? = nil, avatarUrl: String? = nil, roles: [String], ownedSkills: [UserSkill] = [], desiredSkills: [UserSkill] = [], lastLoginAt: Date? = nil, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.authUserId = authUserId
        self.emailSnapshot = emailSnapshot
        self.name = name
        self.username = username
        self.birthDate = birthDate
        self.avatarUrl = avatarUrl
        self.roles = roles
        self.ownedSkills = ownedSkills
        self.desiredSkills = desiredSkills
        self.lastLoginAt = lastLoginAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Helpers
extension AppUser {
    func isCurrentUser(_ cUserId: String?) -> Bool {
        guard let cUserId else { return false }
        return id == cUserId
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

