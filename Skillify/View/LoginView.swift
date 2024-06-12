//
//  LoginView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    @Binding var navigateToSignIn: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack{
                    Spacer()
                    Button {
                        navigateToSignIn = false
                    } label: {
                        Image(systemName: "xmark")
                            .padding(.trailing, 25)
                            .padding(.top, 20)
                            .foregroundColor(.primary)
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                    }
                }
                .padding(.top, 10)
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 60)
                    .padding(.top, 20)
                Text("Welcome back!")
                    .font(.title)
                Text("Login to your account")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                TextLabelView(text: "Enter your email")
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .foregroundColor(.primary)
                    .padding(.bottom, 15)
                    .padding(.horizontal, 20)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextLabelView(text: "Enter your password")
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                Button(action: {
                    Task {
                        do {
                            try await authViewModel.signInWithEmail(email: email, pass: password)
                            // Успешный вход
                        } catch {
                            // Обработка ошибки аутентификации
                            print("Ошибка входа: \(error.localizedDescription)")
                        }
                    }
                }, label: {
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                    Text("Login")
                })
                .frame(width: 250, height: 40)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding()
                
                Text("Or use other methods")
                
                OtherMethodsToSignInView()
//                HStack {
//                    Spacer()
//
//                    Image("googleIcon")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 30, height: 30)
//                        .padding()
//                    Image(systemName: "phone")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 30, height: 30)
//                        .padding()
//                    Image(systemName: "apple.logo")
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: 30, height: 33)
//                        .padding()
//
//                    Spacer()
//                }
                
                Spacer()
                
                // Навигация при успешной аутентификации
//                if viewModel.isAuthenticated {
//                    NavigationLink(destination: AccountView(), isActive: $viewModel.isAuthenticated) { EmptyView() }
//                }
                
            }
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    @State static var navigateToSignIn = true // Создаём временную @State переменную

    static var previews: some View {
        LoginView(navigateToSignIn: $navigateToSignIn) // Передаем Binding переменную
    }
}

struct TextLabelView: View {
    var text: String
    
    var body: some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .foregroundColor(.gray)
    }
}
