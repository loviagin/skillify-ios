//
//  CourseItem.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/19/24.
//

import Foundation

struct CourseItem {
    var title: String = ""
    var description: String = ""
    var image: String = ""
    var sourceUrl: String = ""
    var type: CourseItemType = .url
}

enum CourseItemType: String, Codable {
    case video, url
}
