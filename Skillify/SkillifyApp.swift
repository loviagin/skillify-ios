//
//  SkillifyApp.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI
import TipKit

@main
struct SkillifyApp: App {
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
