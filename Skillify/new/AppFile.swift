//
//  App.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/22/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging

class Delegate: UIResponder, UIApplicationDelegate, MessagingDelegate {
        
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        
        // Запрос разрешений на уведомления
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("FCM токен не получен")
            return
        }
        print("FCM токен устройства: \(fcmToken)")
        
        if Auth.auth().currentUser != nil { // user logged in
            Task { // Создаем асинхронную задачу
                do {
                    if let jwtToken = try await FirebaseService.authenticateAndFetchJwtToken() { // getting a JWT token for making authorized POST request to the server
                        try await FirebaseService.sendAuthorizedRequestToRegisterDevice(fcmToken: fcmToken, jwtToken: jwtToken) // registration a new device or updating existing device info
                    }
                } catch {
                    print("Ошибка при выполнении асинхронной задачи: \(error.localizedDescription)")
                }
            }
        }
    }
}

//@main
struct AppFile: App {
    @UIApplicationDelegateAdaptor(Delegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
