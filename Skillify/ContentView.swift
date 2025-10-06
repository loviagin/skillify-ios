//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            switch viewModel.appState {
            case .idle:
                LoadingView()
                
            case .authenticating:
                StartView()
                
            case .needsProfile(let draft):
                RegistrationView(draft: draft)
                
            case .ready:
                TabsView()
            }
            
            if viewModel.isLoading {
                Color.black.opacity(0.05).ignoresSafeArea()
                ProgressView("Please wait…")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
        .animation(.snappy, value: stateKey)
        .alert(item: Binding(
            get: { viewModel.error.map { ErrorBox(message: $0) } },
            set: { _ in viewModel.error = nil }
        )) { box in
            Alert(title: Text("Error"), message: Text(box.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private var stateKey: String {
        switch viewModel.appState {
        case .idle: return "idle"
        case .authenticating: return "auth"
        case .needsProfile: return "needs"
        case .ready: return "ready"
        }
    }
    
    private struct ErrorBox: Identifiable { let id = UUID(); let message: String }
}

#Preview {
    ContentView()
}
