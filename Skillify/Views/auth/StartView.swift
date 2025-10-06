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
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 300)
                
                Spacer()
                                
                VStack(spacing: 15) {
                    Text("Welcome to Learnsy! Hone your skills anytime, anywhere, with people from all around the world")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .bold()
                        .padding(.vertical)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                    
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
                    
                    Link(destination: URL(string: URLs.privacyUrl)!) {
                        Text("By using Learnsy app you agree to our Privacy Policy")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
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
