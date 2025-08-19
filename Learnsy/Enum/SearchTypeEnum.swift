//
//  SearchTypeEnum.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation

enum SearchType: String, CaseIterable, Identifiable {
    case learningsSkills = "Learning skills"
    case selfSkills = "My skills"
    
    var id: Self { self }
}
