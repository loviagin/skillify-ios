//
//  LoginView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @FocusState var focused: LoginFieldType?
    @State var isLoading = false
    
    enum LoginFieldType {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack{
                    Spacer()
                    Button {
                        dismiss()
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
                    .font(.title2)
                
                Text("Login to your account")
                    .font(.headline)
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
                    .focused($focused, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        withAnimation {
                            focused = .password
                        }
                    }
                
                TextLabelView(text: "Enter your password")
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .focused($focused, equals: .password)
                    .submitLabel(.done)
                    .onSubmit() {
                        focused = nil
                        isLoading = true
                        Task {
                            await authViewModel.signInWithEmail(email: email, pass: password) { error in
                                if let error {
                                    print(error)
                                }
                                isLoading = false
                            }
                        }
                    }
                
                Button {
                    isLoading = true
                    Task {
                        await authViewModel.signInWithEmail(email: email, pass: password) { error in
                            if let error {
                                print(error)
                            }
                            isLoading = false
                        }
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                    } else {
                        Label("Login", systemImage: "rectangle.portrait.and.arrow.forward")
                    }
                }
                .frame(width: 250, height: 40)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .padding()
                
                Text("Or use other methods")
                
                OtherMethodsToSignInView(isLoading: $isLoading)
                
                Spacer()
            }
        }
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthViewModel.mock)
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
