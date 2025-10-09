//
//  AppUser.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation

struct AppUser: Codable, Identifiable, Hashable {
    var id: String = ""
    var authUserId: String = ""
    var emailSnapshot: String? = nil
    var name: String? = nil
    var username: String? = nil
    var bio: String? = nil
    var birthDate: Date? = nil
    var avatarUrl: String? = nil
    var roles: [String] = []
    var ownedSkills: [UserSkill] = []
    var desiredSkills: [UserSkill] = []
    var lastLoginAt: Date? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var subscription: Subscription? = nil
    var subscribersCount: Int = 0
    var subscriptionsCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case id
        case authUserId = "auth_user_id"
        case emailSnapshot = "email_snapshot"
        case name
        case username
        case bio
        case birthDate = "birth_date"
        case avatarUrl = "avatar_url"
        case roles
        case ownedSkills = "owned_skills"
        case desiredSkills = "desired_skills"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case subscription
        case subscribersCount = "subscribers_count"
        case subscriptionsCount = "subscriptions_count"
    }
    
    init(id: String, authUserId: String, emailSnapshot: String? = nil, name: String? = nil, username: String? = nil, bio: String? = nil, birthDate: Date? = nil, avatarUrl: String? = nil, roles: [String], ownedSkills: [UserSkill], desiredSkills: [UserSkill], lastLoginAt: Date? = nil, createdAt: Date, updatedAt: Date, subscription: Subscription? = nil, subscribersCount: Int = 0, subscriptionsCount: Int = 0) {
        self.id = id
        self.authUserId = authUserId
        self.emailSnapshot = emailSnapshot
        self.name = name
        self.username = username
        self.bio = bio
        self.birthDate = birthDate
        self.avatarUrl = avatarUrl
        self.roles = roles
        self.ownedSkills = ownedSkills
        self.desiredSkills = desiredSkills
        self.lastLoginAt = lastLoginAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.subscription = subscription
        self.subscribersCount = subscribersCount
        self.subscriptionsCount = subscriptionsCount
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
    
    var formattedSubscribersCount: String {
        if subscribersCount >= 1000000 {
            return String(format: "%.1fM", Double(subscribersCount) / 1000000.0)
        } else if subscribersCount >= 1000 {
            return String(format: "%.1fK", Double(subscribersCount) / 1000.0)
        } else {
            return "\(subscribersCount)"
        }
    }
    
    var formattedSubscriptionsCount: String {
        if subscriptionsCount >= 1000000 {
            return String(format: "%.1fM", Double(subscriptionsCount) / 1000000.0)
        } else if subscriptionsCount >= 1000 {
            return String(format: "%.1fK", Double(subscriptionsCount) / 1000.0)
        } else {
            return "\(subscriptionsCount)"
        }
    }
}

// MARK: - Hashable & Equatable
extension AppUser {
    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Subscription
extension AppUser {
    struct Subscription: Codable {
        let plan: String?
        let status: Status?
        let startedAt: Date?
        let currentPeriodEnd: Date?
        let cancelAtPeriodEnd: Bool?
        let trialEndsAt: Date?
        let autoRenew: Bool?
        let source: Source?
        let entitlements: [String]?
        let meta: [String: String]?
        
        enum Status: String, Codable {
            case none
            case trialing
            case active
            case past_due
            case canceled
            case expired
            case grace
        }
        
        enum Source: String, Codable {
            case appstore
            case stripe
            case promo
            case internalSource = "internal"
        }
    }
}

extension AppUser.Subscription {
    var isActive: Bool {
        status == .active || status == .trialing || status == .grace
    }
    
    var daysLeftInPeriod: Int? {
        guard let end = currentPeriodEnd else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: end).day
    }
    
    func hasEntitlement(_ name: String) -> Bool {
        (entitlements ?? []).contains(name)
    }
}

