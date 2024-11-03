//
//  Notification.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import Foundation

struct Notification: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String = ""
    var body: String = ""
    var date: Date = Date()
    var userId: String = ""
    var isRead: Bool = false
    var type: UrlType = .chat
    var url: String = ""
}

enum UrlType: String, Codable {
    case user = "user"
    case chat = "chat"
}
