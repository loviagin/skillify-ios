//
//  ColorExtension.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation
import SwiftUI

extension Color {
    static func fromRGBAString(_ rgbaString: String) -> Color? {
        let components = rgbaString.split(separator: ",").compactMap { Double($0) }
        return components.count == 4 ? Color(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3]) : nil
    }
}
