//
//  SkillifyApp.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import FirebaseCore
import FirebaseAuth
import SwiftUI
import GoogleSignIn
import OneSignalFramework
import PushKit
import UserNotifications
import CallKit
import AgoraRtcKit
import FirebaseFirestore
import RevenueCat
import TipKit
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var pushRegistry: PKPushRegistry!
    lazy var callManager: CallManager = {
        let manager = CallManager()
        return manager
    }()
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        _ = callManager
        
        OneSignal.initialize("e57ccffe-08a9-4fa8-8a63-8c3b143d2efd", withLaunchOptions: launchOptions)
        
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
        }, fallbackToSettings: true)
        
        // Initialize PushKit
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        Purchases.logLevel = .info
        Purchases.configure(withAPIKey: "appl_XIhpKOSZPgtexHzjEZAwzgGYrMk")
        
        // Настройка тестового устройства
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
            "6aba2884a16b839276f5647143ccea74"
        ]
        
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: - PKPushRegistryDelegate
extension AppDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        guard type == .voIP else { return }
        
        if let user = Auth.auth().currentUser {
            let deviceTokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
            print("VoIP Token: \(deviceTokenString)")
            
            // Регистрация устройства в OneSignal
            Task {
                await registerVoIPTokenWithOneSignal(deviceTokenString, id: user.uid)
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard type == .voIP else {
            completion()
            return
        }
        
        if let custom = payload.dictionaryPayload["custom"] as? [String: Any],
           let a = custom["a"] as? [String: Any] {
            
            let callUUID = a["uuid"] as? String ?? ""
            let callerId = a["caller"] as? String ?? "Unknown Caller"
            let callStatus = a["callStatus"] as? String ?? "incoming"
            let channelName = a["channelName"] as? String ?? ""
            let token = a["token"] as? String ?? ""
            let uid = a["uid"] as? UInt ?? 0
            let videoCall = a["hasVideo"] as? Bool ?? false
            
            if callStatus == "incoming" {
                // Обработка входящего звонка
                print("incoming voip cheched")
                if uid != 0 {
                    callManager.agoraManager.users.append(UInt.random(in: 1...1000))
                    callManager.agoraManager.users.append(uid)
                }
                callManager.setCall(caller: callerId, uuid: callUUID, channelName: channelName, hasVideo: videoCall, token: token) {
                    self.callManager.reportIncomingCall()
                }
            } else if callStatus == "ended" {
                print("ending voip cheched")
                // Обработка завершения звонка
                callManager.endCall()
            }
        } else {
            print("Invalid payload structure")
        }
        
        completion()
    }
    
    func registerVoIPTokenWithOneSignal(_ voipToken: String, id: String) async {
        let parameters = [
          "identity": ["external_id": id],
          "subscriptions": [
            [
              "type": "iOSPush",
              "token": voipToken,
              "enabled": true
            ]
          ]
        ] as [String : Any?]

        let postData = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        if let user = Auth.auth().currentUser {
            if let token = UserDefaults.standard.string(forKey: "voipToken"), token != voipToken {
                try? await Firestore.firestore().collection("users").document(user.uid).updateData(["devices": FieldValue.arrayUnion([voipToken])])
            } else if UserDefaults.standard.string(forKey: "voipToken") == nil {
                UserDefaults.standard.set(voipToken, forKey: "voipToken")
                try? await Firestore.firestore().collection("users").document(user.uid).updateData(["devices": FieldValue.arrayUnion([voipToken])])
            }
        }

        let url = URL(string: "https://api.onesignal.com/apps/5e75a1c5-4bab-42cc-8329-b697e85d92f7/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "content-type": "application/json"
        ]
        request.httpBody = postData
   
        let _ = try? await URLSession.shared.data(for: request)
    }
}

@main
struct SkillifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(chatViewModel)
                .environmentObject(delegate.callManager)
                .task {
                    try? Tips.configure([
                        .displayFrequency(.immediate)
                    ])
                }
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            switch newScenePhase {
            case .background:
                Task {
                    await authViewModel.offlineMode()
                }
            case .active:
                Task {
                    await authViewModel.onlineMode()
                }
            default:
                break
            }
        }
    }
}
