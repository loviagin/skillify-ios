//
//  Chat.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation

struct Chat: Identifiable, Codable, Hashable, Equatable {
    var id: String = UUID().uuidString
    var cUid: String = ""
    var text: String? = nil
    var mediaUrl: String? = nil
    var time: Double? = nil
    var date: Date? = Date()
    var status: String? = "u" // u - unread, r - read
    var emoji: String? = nil 
    var replyTo: [String]? = nil
    var reply: String? = nil
    var type: ChatType? = .text
    var tags: [String]? = nil
}

enum ChatType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case call = "call"
    case file = "file"
}
