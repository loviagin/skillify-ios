//
//  ArrayEstension.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
