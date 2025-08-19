//
//  AuthView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct AuthView: View {
    @State private var showSafari = false
    //    @State private var stackVisible = false
    
    @State var navigateToRegister = false
    @State var navigateToSignIn = false
    
    var body: some View {
        NavigationStack {
            VStack {
//                Image("logo")
//                    .resizable(resizingMode: .stretch)
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 180, height: 30.0)
//                    .padding()
                
                Image("mainImage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .padding()
                
                Text("Welcome to Learnsy! Hone your skills anytime, anywhere, with people from all around the world")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                ButtonTextView(textButton: "Create an account", colorButton: .redApp) {
                    navigateToRegister = true
                }
                .sheet(isPresented: $navigateToRegister) {
                    RegisterView(navigateToRegister: $navigateToRegister)
                }
                
                // Кнопка для перехода на экран входа
                ButtonTextView(textButton: "Sign in", colorButton: .brandBlue) {
                    navigateToSignIn = true
                }
                .sheet(isPresented: $navigateToSignIn){
                    LoginView()
                }
                
                Text("By using Learnsy app you agree to our Privacy Policy")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    .onTapGesture {
                        showSafari = true
                    }
                    .sheet(isPresented: $showSafari) {
                        SafariView(url:
                                    URL(string: "https://lovigin.com/privacy-policy/")!)
                    }
            }
            .frame(maxWidth: .infinity)
            .background(.background)
            .cornerRadius(15)
            //                .offset(y: stackVisible ? 0 : UIScreen.main.bounds.height)
            //            }
            //            .background(.brandBlue)
            //            .ignoresSafeArea()
            //            .onAppear {
            //                withAnimation(.spring()) {
            //                    stackVisible = true // Активируем анимацию, когда View появляется
            //                }
            //            }
        }
    }
}

struct ButtonTextView: View {
    var textButton: String
    var colorButton: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(textButton)
                .frame(width: 300, height: 45)
                .background(colorButton)
                .foregroundColor(.white)
                .cornerRadius(25)
        }
        .padding(.top, 10)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel.mock)
}
