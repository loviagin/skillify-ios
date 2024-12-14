//
//  GamePoint.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation

struct GamePoint: Codable, Equatable {
    var name: String = ""
    var date: Date = Date()
    var value: Int = 0
    var type: GameType = .points
}
