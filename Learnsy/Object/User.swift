//
//  User.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 18.12.2023.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var first_name: String = ""
    var last_name: String = ""
    var bio: String = ""
    var email: String = ""
    var language: String = "en"
    var block: String? = nil
    var nickname: String = ""
    var phone: String = ""
    var urlAvatar: String = ""
    var online: Bool? = true
    var sex: String = "-"
    var birthday: Date = Date()
    var proDate: Date? = nil
    var registered: Date? = Date()
    
    var favorites: [Favorite] = []
    var calls: [[String: String]]? = nil
    var learningSkills: [Skill] = []
    var messages: [[String: String]]? = nil
    var selfSkills: [Skill] = []
    var blockedUsers: [String] = []
    var devices: [String] = []
    var notifications: [String]? = nil
    var subscribers: [String] = []
    var subscriptions: [String] = []
    var lastData: [String]? = ["ios", UserHelper.getStringDate(), UserHelper.getAppVersion()]
    var tags: [String]? = ["user"]
    var proData: [String]? = nil
    var courses: [String]? = []
    var privacyData: [String]? = []
}
