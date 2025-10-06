//
//  Limits.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import Foundation

final class Limits {
    static let maxNameLength = 50
    static let maxNicknameLength = 30
    static var maxBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -12, to: Date()) ?? Date()
    }
}
