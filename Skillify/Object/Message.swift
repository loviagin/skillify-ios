//
//  Message.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 23.12.2023.
//

import Foundation
 
struct Message: Identifiable, Codable, Hashable {
    var id: String
    var lastData: [String]
    var messages: [Chat]?
    var time: Double?
    var uids: [String]
    
    enum CodingKeys: String, CodingKey {
        case id
        case lastData
        case messages
        case time
        case uids
    }
}
