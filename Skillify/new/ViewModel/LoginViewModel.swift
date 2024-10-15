//
//  AuthViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/21/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

class LoginViewModel: ObservableObject {
    @Published var status: AuthStatus
        
    init() {
        if Auth.auth().currentUser != nil {
            self.status = .loggedIn
            print("logged in as \(Auth.auth().currentUser!.email!)")
//            registerDevice(userId: Auth.auth().currentUser?.uid ?? "")
        } else {
            self.status = .loggedOut
            print("logged out")
        }
        
        addAuthStateListener()
    }
    
    private func addAuthStateListener() {
        Auth.auth().currentUser?.reload(completion: { (error) in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.userDisabled.rawValue {
                    // Аккаунт отключен
                    print("Аккаунт пользователя отключен.")
                    try? Auth.auth().signOut()
                }
            }
        })
    }
    
//    func registerDevice(userId: String) {
//        let db = Firestore.firestore()
//        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
//        let token = Messaging.messaging().fcmToken
//        
//        let deviceData: [String: Any] = [
//            "deviceId": deviceId,
//            "token": token ?? ""
//        ]
//
//        db.collection("users").document(userId).collection("devices").document(deviceId).setData(deviceData) { error in
//            if let error = error {
//                print("Error registering device: \(error.localizedDescription)")
//            } else {
//                print("Device registered successfully.")
//            }
//        }
//    }
}

