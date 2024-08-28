//
//  Chat.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation

struct Message: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var userId: String = ""
    var text: String?
    var messageType: MessageType = .text
    var status: String = "sent" // or read
    var media: [String]? = nil
    var time: Date = Date()
    var reply: String? = nil
    var emoji: String? = nil
    var info: [String]? = nil
    var tags: [String]? = nil
    var blocked: String? = nil
}

enum MessageType: String, Codable {
    case text = "text"
    case photo = "photo"
    case video = "video"
    case call = "call"
    case file = "file"
}
