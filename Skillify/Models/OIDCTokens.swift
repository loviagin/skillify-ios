//
//  OIDCTokens.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import Foundation

struct OIDCTokens: Codable {
    let accessToken: String
    let refreshToken: String?
    let idToken: String?
    let tokenType: String
    let expiresIn: Int?
}
