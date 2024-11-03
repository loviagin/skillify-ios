//
//  Member.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/2/24.
//

import Foundation

struct Member: Codable, Hashable {
    var userId: String = ""
    var level: MemberLevel = .usually
}

enum MemberLevel: String, Codable {
    case admin = "admin"
    case usually = "usually"
}
