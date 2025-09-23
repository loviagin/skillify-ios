//
//  ContentView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 5/10/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        VStack(spacing: 16) {
            Text("Skillify Auth")
                .font(.largeTitle).bold()

            if let user = vm.userInfo {
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

            Button {
                vm.signIn()
            } label: {
                Text(vm.isLoading ? "Opening…" : "Sign in")
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(vm.isLoading)

            if let err = vm.error {
                Text(err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }

            if vm.tokens != nil {
                Button(role: .destructive) {
                    vm.rpLogout()
                } label: {
                    Text("Sign out")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
