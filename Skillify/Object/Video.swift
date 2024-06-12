//
//  Video.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import Foundation

struct Video: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var url: String = ""
//    var image
    var userId: String = ""
    var seen: [String] = []
    var tags: [String] = []
}
