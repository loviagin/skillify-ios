//
//  Course.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import Foundation

struct Course: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var userId: String = ""
    var preview: String = ""
    var title: String = ""
    var description: String = ""
    var rating: Double = 0.0
    var categorySkill: String = ""
    var block: String? = nil
    var createdAt: Date = Date()
}
