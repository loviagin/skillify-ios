//
//  UserModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/21/24.
//

import Foundation

struct UserModel: Identifiable, Codable, Hashable {
    var id: Int
    var name: String
}
