//
//  AppUserDraft.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import Foundation

struct AppUserDraft: Codable {
    var sub: String
    var email: String?
    var name: String?
    var avatarUrl: String?
}
