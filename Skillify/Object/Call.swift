//
//  Call.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 30.12.2023.
//

import Foundation

struct Call: Codable, Identifiable {
    var id: String
//    var chanelId: String
    var token: String
    var channelName: String
    var uids: [String]
    var active: Bool = false
    var joinedUsers: [String]? = nil
}

extension Call {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "token": token,
            "channelName": channelName,
            "uids": uids,
            "active": active,
            "joinedUsers": joinedUsers ?? []
        ]
    }
}
