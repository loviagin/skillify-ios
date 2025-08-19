//
//  EmailRegistrationView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI

struct EmailRegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    
    @FocusState var focused: EmailRegisterType?
    @State private var isLoading: Bool = false
    
    enum EmailRegisterType {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("Create account")
                    .foregroundColor(.primary)
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top, 10)
                Text("Using your email address")
                    .padding(.bottom, 20)
                
                Text("Your email")
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .focused($focused, equals: .email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                    .submitLabel(.next)
                    .onSubmit {
                        withAnimation {
                            focused = .password
                        }
                    }
                
                Text("Create a password")
                SecureField("* * * * * *", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                    .focused($focused, equals: .password)
                    .submitLabel(.done)
                    .onSubmit {
                        focused = nil
                        isLoading = true
                        Task {
                            try await authViewModel.createUserByEmail(email: email, pass: password) { error in
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
                        try await authViewModel.createUserByEmail(email: email, pass: password) { error in
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
                        Text("Register")
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(.blue)
                .cornerRadius(15)
                Spacer()
            }
            .padding()
        }
        .onAppear {
            focused = .email
        }
    }
}

#Preview {
    EmailRegistrationView()
        .environmentObject(AuthViewModel.mock)
}
