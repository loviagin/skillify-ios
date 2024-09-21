//
//  Media.swift
//  Communa
//
//  Created by Ilia Loviagin on 7/13/24.
//

import Foundation

struct Media: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var url: String = ""
    var placeholder: String? = nil
    var type: MediaType = .photo
    var info: [String] = []
    var blocked: String? = nil
}

enum MediaType: String, Codable {
    case photo = "photo"
    case video = "video"
}
