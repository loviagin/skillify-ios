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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 10)
                
                Text("Create a password")
                SecureField("* * * * * *", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.bottom, 20)
                
                Button {
                    Task {
                        try await authViewModel.createUser(email: email, pass: password)
                    }
                } label: {
                    HStack{
                        Spacer()
                        Text("Register")
//                            .font(.title3)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(width: .infinity, height: 40)
                    .background(.blue)
                    .cornerRadius(15)
                }
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    EmailRegistrationView()
}
