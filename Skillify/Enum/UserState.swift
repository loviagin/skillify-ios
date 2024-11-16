//
//  UserState.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/16/24.
//

import Foundation

enum UserState: Equatable {
    case loading
    case loggedOut
    case loggedIn
    case profileEditRequired
    case blocked(reason: String?)
}
