//
//  StartView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/23/25.
//

import SwiftUI

struct StartView: View {
    @EnvironmentObject private var viewModel: AuthViewModel
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 55) {
                Image(.newLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 70)
                                
                Image(.mainPicture)
                
                Text("Welcome to Learnsy! Hone your skills anytime, anywhere, with people from all around the world")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .bold()
                
                #if debug
                if let user = viewModel.userInfo {
                    VStack(spacing: 6) {
                        Text("Signed in").font(.headline)
                        Text("sub: \(user.sub)").font(.footnote).foregroundStyle(.secondary)
                        if let name = user.name { Text("name: \(name)").font(.footnote) }
                        if let email = user.email { Text("email: \(email)").font(.footnote) }
                    }
                } else {
                    Text("You are not signed in")
                        .foregroundStyle(.secondary)
                }
                #endif
                                
                VStack(spacing: 15) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // DEBUG: Кнопка для очистки сессии
                    #if DEBUG
                    if viewModel.userInfo != nil {
                        Button(action: {
                            print("[StartView] Clearing session manually")
                            viewModel.signOut()
                        }) {
                            Text("Clear Session (Debug)")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    #endif
                    
                    AppButton(text: "Get Started", background: .newPink, isLoading: $isLoading) {
                        withAnimation {
                            isLoading = true
                            errorMessage = nil
                        }
                        
                        viewModel.signIn()
                    }
                    .onChange(of: viewModel.isLoading) { _, newValue in
                        withAnimation {
                            isLoading = newValue
                        }
                    }
                    .onChange(of: viewModel.error) { _, newValue in
                        withAnimation {
                            errorMessage = newValue
                        }
                    }
                    
                    Link(destination: URL(string: "https://auth.lovig.in/privacy")!) {
                        Text("By using Learnsy app you agree to our Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
//                .padding(.top)
            }
            .padding(20)
        }
        .scrollIndicators(.never)
    }
}

#Preview {
    StartView()
        .environmentObject(AuthViewModel.mock)
}
