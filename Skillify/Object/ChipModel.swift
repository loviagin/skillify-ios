//
//  Chip.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 01.02.2024.
//

import Foundation
import SwiftUI

struct ChipModel: Identifiable {
    var isSelected: Bool
    let id = UUID()
    let systemImage: String
    let titleKey: String
}
