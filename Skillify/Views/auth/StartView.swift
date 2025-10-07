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
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let isTall = h > 800
            let logoWidth = min(w * 0.55, 260)
            let illustrationHeight = min(h * (isTall ? 0.40 : 0.34), 460)
            let verticalPadding: CGFloat = 20

            ScrollView {
                VStack(spacing: isTall ? 40 : 28) {
                    // Logo
                    Image(.newLogo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoWidth)
                        .padding(.top, isTall ? 10 : 0)

                    // Illustration
                    Image(.mainPicture)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: illustrationHeight)

                    Spacer(minLength: isTall ? h * 0.12 : 0)

                    // CTA
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
                .frame(minHeight: h - verticalPadding * 2)
                .padding(20)
            }
            .scrollIndicators(.never)
        }
    }
}

#Preview {
    StartView()
        .environmentObject(AuthViewModel.mock)
}
