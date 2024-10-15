//
//  DeviceModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/22/24.
//

import Foundation

struct DeviceModel: Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var fcmToken: String
    var lastLoginDate: Date = Date()
    var blocked: Bool = false
}
