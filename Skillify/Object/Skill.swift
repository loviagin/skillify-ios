//
//  Skill.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 18.12.2023.
//

import Foundation

struct Skill: Codable, Identifiable, Equatable, Hashable {
    var id = UUID()
    var name: String
    var iconName: String?
    var level: String?
    var isSelected = false
    
    enum CodingKeys: String, CodingKey {
        case name
        case level
    }
}

