//
//  ProfileView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/6/25.
//

import SwiftUI
import PhotosUI

struct AccountView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var userViewModel: UserViewModel
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showEditSheet = false
    @State private var showSignOutConfirmation = false
    
    init(userViewModel: UserViewModel) {
        _userViewModel = StateObject(wrappedValue: userViewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if userViewModel.isLoading {
                        ProgressView("Loading...")
                            .padding()
                    } else if let user = userViewModel.currentUser {
                        // Avatar
                        VStack {
                            AvatarView(avatarImage: .constant(nil), avatarUrl: .constant(user.avatarUrl))
                        }
                        .padding(.vertical)
                        
                        // User Info
                        VStack(spacing: 16) {
                            InfoRow(title: "Name", value: user.name ?? "—")
                            InfoRow(title: "Username", value: user.username ?? "—")
                            InfoRow(title: "Email", value: user.emailSnapshot ?? "—")
                            if let age = user.age {
                                InfoRow(title: "Age", value: "\(age) years")
                            }
                            if let birthDate = user.formattedBirthDate {
                                InfoRow(title: "Birth Date", value: birthDate)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Edit Button
                        Button {
                            showEditSheet = true
                        } label: {
                            Text("Edit Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Sign Out Button
                        Button {
                            showSignOutConfirmation = true
                        } label: {
                            Text("Sign Out")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                    } else {
                        Text("No profile data")
                            .foregroundStyle(.secondary)
                            .padding()
                        
                        Button("Reload") {
                            Task {
                                await userViewModel.fetchProfile()
                            }
                        }
                    }
                    
                    if let error = userViewModel.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .onAppear {
                if userViewModel.currentUser == nil {
                    Task {
                        await userViewModel.fetchProfile()
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await userViewModel.updateAvatar(image)
                    }
                }
            }
            .refreshable {
                await userViewModel.fetchProfile()
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authViewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out? This will end your session on all devices.")
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    AccountView(userViewModel: UserViewModel.mock)
        .environmentObject(AuthViewModel.mock)
}

