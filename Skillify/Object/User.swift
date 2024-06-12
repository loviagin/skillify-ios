//
//  User.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 18.12.2023.
//

import Foundation

struct User: Identifiable, Codable, Hashable {
    
    var id: String
    var first_name: String
    var last_name: String
    var bio: String = ""
    var email: String
    var language: String = "en"
    var blocked: Int = 0
    var block: String? = nil
    var nickname: String
    var phone: String
    var urlAvatar: String = ""
    var online: Bool? = true
    var sex: String = "-"
    var birthday: Date
    var pro: Double = 0
    var favorites: [Favorite] = []
    var calls: [[String: String]] = []
    var learningSkills: [Skill] = []
    var messages: [[String: String]] = []
    var selfSkills: [Skill] = []
    var blockedUsers: [String] = []
    var devices: [String] = []
    var notifications: [String] = []
    var subscribers: [String] = []
    var subscriptions: [String] = []
    var lastData: [String]?
    var tags: [String]?
    var proData: [String]?
    var courses: [String]?
    var privacyData: [String]?
    
    init(id: String, first_name: String, last_name: String, bio: String, email: String, language: String, blocked: Int, nickname: String, phone: String, urlAvatar: String, online: Bool, sex: String, birthday: Date, pro: Double, favorites: [Favorite], calls: [[String: String]], learningSkills: [Skill], messages: [[String : String]], selfSkills: [Skill], blockedUsers: [String], block: String?, devices: [String], notifications: [String], subscribers: [String], subscriptions: [String], lastData: [String]?, tags: [String]?, proData: [String]?, courses: [String]?, privacyData: [String]?) {
        self.id = id
        self.first_name = first_name
        self.last_name = last_name
        self.bio = bio
        self.email = email
        self.language = language
        self.blocked = blocked
        self.nickname = nickname
        self.phone = phone
        self.urlAvatar = urlAvatar
        self.online = online
        self.sex = sex
        self.block = block
        self.birthday = birthday
        self.pro = pro
        self.favorites = favorites
        self.calls = calls
        self.learningSkills = learningSkills
        self.messages = messages
        self.selfSkills = selfSkills
        self.blockedUsers = blockedUsers
        self.devices = devices
        self.notifications = notifications
        self.subscribers = subscribers
        self.subscriptions = subscriptions
        self.lastData = lastData
        self.tags = tags
        self.proData = proData
        self.courses = courses
        self.privacyData = privacyData
    }
    
    init(id: String, first_name: String, last_name: String, email: String, nickname: String, phone: String, birthday: Date) {
        self.id = id
        self.first_name = first_name
        self.last_name = last_name
        self.bio = ""
        self.email = email
        self.language = "en"
        self.blocked = 0
        self.block = nil
        self.nickname = nickname
        self.phone = phone
        self.urlAvatar = ""
        self.online = true
        self.sex = "-"
        self.birthday = birthday
        self.pro = 0
        self.calls = []
        self.learningSkills = []
        self.messages = []
        self.selfSkills = []
        self.blockedUsers = []
        self.devices = []
        self.notifications = []
        self.subscribers = []
        self.subscriptions = []
        self.lastData = ["ios", UserHelper.getStringDate(), UserHelper.getAppVersion()]
        self.tags = ["user"]
        self.proData = []
        self.courses = []
        self.privacyData = []
    }
    
    init() {
        self.id = ""
        self.first_name = ""
        self.last_name = ""
        self.bio = ""
        self.email = ""
        self.language = "en"
        self.blocked = 0
        self.block = nil
        self.nickname = ""
        self.phone = ""
        self.urlAvatar = ""
        self.online = true
        self.sex = "-"
        self.birthday = Date()
        self.pro = 0
        self.favorites = []
        self.calls = []
        self.learningSkills = []
        self.messages = []
        self.selfSkills = []
        self.blockedUsers = []
        self.devices = []
        self.notifications = []
        self.subscribers = []
        self.subscriptions = []
        self.lastData = ["ios", UserHelper.getStringDate(), UserHelper.getAppVersion()]
        self.tags = ["user"]
        self.courses = []
        self.privacyData = []
    }
}
