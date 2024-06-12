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
    var description: String = ""
}
