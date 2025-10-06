//
//  OIDCUserInfo.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import Foundation

struct OIDCUserInfo: Codable {
    let sub: String
    let name: String?
    let email: String?
    let email_verified: Bool?
}
