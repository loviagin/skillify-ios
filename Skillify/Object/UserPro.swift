//
//  UserPro.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 14.02.2024.
//

import Foundation

struct UserPro: Identifiable, Codable {
    var id: String
    var first_name: String
    var avatarUrl: String
    var onlineStatus: Bool
}
