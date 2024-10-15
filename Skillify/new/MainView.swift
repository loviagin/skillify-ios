//
//  MainView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/21/24.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        Group {
            switch viewModel.status {
            case .loggedIn:
                HomeView()
                    .transition(.slide)
            case .loggedOut:
                WelcomeScreenView()
                    .transition(.move(edge: .bottom))
            case .blocked:
                UserBlockView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: viewModel.status)
    }
}

#Preview {
    MainView()
}
