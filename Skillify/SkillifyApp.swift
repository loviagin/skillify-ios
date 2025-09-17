//
//  SkillifyApp.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
//import GoogleMobileAds
import TipKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Настройка тестового устройства
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [
//            "6aba2884a16b839276f5647143ccea74"
//        ]
        
//        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        return true
    }
}

@main
struct SkillifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    try? Tips.configure([
                        .displayFrequency(.immediate)
                    ])
                }
        }
        .onChange(of: scenePhase) { _, newScenePhase in
            switch newScenePhase {
            case .background:
                break
            case .active:
                break
            default:
                break
            }
        }
    }
}
