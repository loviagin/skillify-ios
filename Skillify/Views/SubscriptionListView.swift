//
//  SubscriptionListView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/9/25.
//

import SwiftUI

struct SubscriptionListView: View {
    let user: AppUser
    let initialTab: SubscriptionTab
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab: SubscriptionTab
    @State private var subscribers: [AppUser] = []
    @State private var subscriptions: [AppUser] = []
    @State private var isLoading = false
    @State private var error: String?
    
    init(user: AppUser, initialTab: SubscriptionTab = .subscribers) {
        self.user = user
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }
    
    enum SubscriptionTab: CaseIterable {
        case subscribers, subscriptions
        
        var title: String {
            switch self {
            case .subscribers: return "Subscribers"
            case .subscriptions: return "Following"
            }
        }
        
        var icon: String {
            switch self {
            case .subscribers: return "person.2.fill"
            case .subscriptions: return "person.badge.plus.fill"
            }
        }
    }
    
    private var userViewModel: UserViewModel {
        authViewModel.userViewModel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                tabSelector
                
                // Content
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else {
                    usersList
                }
            }
            .navigationTitle("\(user.name ?? "User")")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadData()
            }
            .onChange(of: selectedTab) { _, _ in
                loadData()
            }
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(SubscriptionTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.title)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("\(getCount(for: tab))")
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // MARK: - Users List
    private var usersList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(getUsers(for: selectedTab)) { user in
                    UserRowView(user: user, selectedTab: selectedTab)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading...")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            Text("Error")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(error)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                loadData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Methods
    private func getCount(for tab: SubscriptionTab) -> Int {
        switch tab {
        case .subscribers:
            return user.subscribersCount
        case .subscriptions:
            return user.subscriptionsCount
        }
    }
    
    private func getUsers(for tab: SubscriptionTab) -> [AppUser] {
        switch tab {
        case .subscribers:
            return subscribers
        case .subscriptions:
            return subscriptions
        }
    }
    
    private func loadData() {
        print("🔄 Loading data for tab: \(selectedTab), user: \(user.id)")
        isLoading = true
        error = nil
        
        Task {
            do {
                switch selectedTab {
                case .subscribers:
                    print("📥 Loading subscribers for user: \(user.id)")
                    let users = await userViewModel.getUserFollowers(userId: user.id)
                    print("📥 Loaded \(users.count) subscribers")
                    await MainActor.run {
                        self.subscribers = users
                        self.isLoading = false
                    }
                case .subscriptions:
                    print("📤 Loading subscriptions for user: \(user.id)")
                    let users = await userViewModel.getUserSubscriptions(userId: user.id)
                    print("📤 Loaded \(users.count) subscriptions")
                    await MainActor.run {
                        self.subscriptions = users
                        self.isLoading = false
                    }
                }
            } catch {
                print("❌ Error loading data: \(error)")
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - User Row View
struct UserRowView: View {
    let user: AppUser
    let selectedTab: SubscriptionListView.SubscriptionTab
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    private var userViewModel: UserViewModel {
        authViewModel.userViewModel
    }
    
    var body: some View {
        NavigationLink(destination: ProfileView(user: user).environmentObject(authViewModel)) {
            HStack(spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.gray)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name ?? "Unknown")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let username = user.username {
                        Text("@\(username)")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Follow Button (if not current user and not in subscriptions tab)
                if !user.isCurrentUser(userViewModel.currentUser?.id) && selectedTab != .subscriptions {
                    Button {
                        // TODO: Implement follow/unfollow
                    } label: {
                        Text("Follow")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
