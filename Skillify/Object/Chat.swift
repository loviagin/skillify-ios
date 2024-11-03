//
//  Message.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
 
struct Chat: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var users: [String] = []
    var last: LastData = LastData()
    var lastTime: Date = Date()
    var tags: [String]? = nil
    var info: [String]? = nil
    var blocked: String? = nil
    var status: ChatStatus? = nil
    var type: ChatType = .personal
    
    func getUser(_ cUid: String) -> String? {
        return users.first(where: { $0 != cUid })
    }
}

struct ChatStatus: Codable, Hashable {
    var userId: String = ""
    var action: String = ""
}

enum ChatType: String, Codable {
    case personal = "personal"
    case privateGroup = "privateGroup"
    case publicGroup = "publicGroup"
}
