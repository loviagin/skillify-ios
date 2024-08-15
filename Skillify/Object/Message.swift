//
//  Message.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
 
struct Message: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var lastData: [String]? = nil
    var last: LastData? = nil
    var messages: [Chat] = []
    var time: Double? = nil
    var date: Date? = Date()
    var uids: [String]? = nil
    var members: [Member]? = []
    var type: MessageType? = .personal
}

enum MessageType: String, Codable {
    case personal = "personal"
    case privateGroup = "privateGroup"
    case publicGroup = "publicGroup"
}
