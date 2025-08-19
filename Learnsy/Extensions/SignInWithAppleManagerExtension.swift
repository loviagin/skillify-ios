//
//  SignInWithAppleManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation
import AuthenticationServices

extension SignInWithAppleManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAuthorization(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleAuthorizationError(error)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("Unable to retrieve a UIWindowScene")
        }
        return windowScene.windows.first { $0.isKeyWindow }!
    }
}
