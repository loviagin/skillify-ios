//
//  AuthViewModelExtension.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation
import SwiftUI

extension AuthViewModel {
    func getRootViewController() -> UIViewController? {
        // Attempt to find the root view controller of the current key window
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?.rootViewController
    }
    
    static var mock: AuthViewModel {
        let viewModel = AuthViewModel()
        viewModel.currentUser = User(id: "Support", first_name: "Elia", last_name: "Loviagin", email: "ilia@loviagin.com", nickname: "nick", phone: "+70909998876", birthday: Date())
        viewModel.currentUser?.proData = ["user", "cover:3"]
        viewModel.currentUser?.urlAvatar = "avatar2"
        viewModel.currentUser?.devices = ["f3498hervuhivuheiqidcjeq", "owivje9qfh9r8euqw9e"]
        return viewModel
    }
}
