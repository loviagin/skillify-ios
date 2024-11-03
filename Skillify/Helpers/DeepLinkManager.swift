//
//  DeepLinkManager.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 05.03.2024.
//

import Foundation
import SwiftUI

class DeepLinkManager: ObservableObject {
    @Published var profileID: String?

    static let shared = DeepLinkManager()

    private init() {}

    func handleDeepLink(url: URL) {
        print("kkkkkk")
        // Парсинг URL, например, "Skillify:profile/id12345"
        let urlString = url.absoluteString
        if urlString.starts(with: "skillify:profile/") {
            self.profileID = urlString.replacingOccurrences(of: "skillify:profile/", with: "")
        }
    }
}
