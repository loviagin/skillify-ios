//
//  Favorite.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 03.02.2024.
//

import Foundation

struct Favorite: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var type: String = "user"
}
