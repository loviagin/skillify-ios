//
//  NotificationsView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 19.12.2023.
//

import SwiftUI
import FirebaseAuth

struct NotificationsView: View {
    @StateObject var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            if viewModel.notifications.isEmpty {
                ContentUnavailableView("No notifications yet", systemImage: "bubble.right.circle")
            }
            
            List {
                ForEach(viewModel.notifications) { item in
                    NotificationItemView(notification: item)
                        .environmentObject(viewModel)
                }
            }
            .listStyle(.inset)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                viewModel.loadNotifications(for: Auth.auth().currentUser?.uid ?? "")
            }
        }
    }
}

struct NotificationItemView: View {
    @EnvironmentObject private var viewModel: NotificationsViewModel
    let notification: Notification
    @State private var user = User()
    @State private var showProfile: User?
    @State private var showChat: Message?
    
    var body: some View {
        Button {
            withAnimation {
                switch notification.type {
                case .user:
                    showProfile = user
                case .chat:
                    showChat = Message(userId: notification.url)
                }
            }
        } label: {
            GroupBox {
                HStack(alignment: .center, spacing: 20) {
//                    Avatar2View(avatarUrl: user.urlAvatar, size: 30, maxHeight: 30, maxWidth: 30)
                    
                    VStack(alignment: .leading) {
                        Text(notification.title)
                            .bold()
                        Text(notification.body)
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationDestination(item: $showChat) { message in
            MessagesView(userId: message.userId)
                .toolbar(.hidden, for: .tabBar)
        }
        .navigationDestination(item: $showProfile) { user in
            ProfileView(user: user)
        }
        .onAppear {
            viewModel.getUser(uid: notification.userId) { user in
                self.user = user
            }
        }
    }
}

#Preview {
    NotificationsView(viewModel: NotificationsViewModel.mock)
}
