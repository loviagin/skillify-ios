//
//  Chat.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation

struct Chat: Identifiable, Codable, Hashable, Equatable {
    var id: String
    var cUid: String
    var text: String?
    var mediaUrl: String? = nil
    var time: Double
    var status: String? = "u" // u - unread, r - read
    var emoji: String? = nil 
    var replyTo: [String]?
    var type: ChatType? = .text
    
    enum CodingKeys: String, CodingKey {
        case id
        case cUid
        case mediaUrl
        case text
        case time
        case status
        case emoji
        case replyTo
    }
}

enum ChatType: String, Codable {
    case text = "text"
    case image = "image"
    case video = "video"
    case call = "call"
    case file = "file"
}
