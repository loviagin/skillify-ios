//
//  SubscribersView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 29.12.2023.
//

import SwiftUI
import FirebaseFirestore

struct SubscribersView: View {
    @State var selection = SubscribersViewModel.SubscribersCategory.subscribers
    var subscribers: [String]
    var subscriptions: [String]

    @State var subscribersList: [User] = []
    @State var subscriptionsList: [User] = []
    
    var body: some View {
        VStack {
            Picker("Search Category", selection: $selection) {
                ForEach(SubscribersViewModel.SubscribersCategory.allCases, id: \.self) { category in
                    Text(category.tabTitle).tag(category)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            ScrollView {
                VStack {
                    ForEach(selection == .subscribers ? subscribers : subscriptions, id: \.self) { user in
                        UserView(isFirst: selection == .subscribers ? true : false, cUid: user, subscribersList: $subscribersList, subscriptionsList: $subscriptionsList)
                    }
                }
            }
//            .listStyle(PlainListStyle())
            
            Spacer()
        }
    }
}

#Preview {
    SubscribersView(selection: SubscribersViewModel.SubscribersCategory.subscribers, subscribers: [], subscriptions: [])
}

struct UserView: View {
    var isFirst: Bool
    var cUid: String
    @State var user: User = User()
    @Binding var subscribersList: [User]
    @Binding var subscriptionsList: [User]
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var activeSkillManager = ActiveSkillManager() // Создание экземпляра
    
    var body: some View {
        VStack {
            UserCardView(user: user, authViewModel: authViewModel, activeSkillManager: activeSkillManager, id: authViewModel.currentUser!.id)
                .foregroundColor(.primary)
                .padding()
        }
        .onAppear {
            if isFirst { // subscribers
                if let index = subscribersList.firstIndex(where: { $0.id == cUid }) {
                    user = subscribersList[index]
                } else {
                    let ref = Firestore.firestore().collection("users").document(cUid)
                    Task {
                        do {
                            let snapshot = try await ref.getDocument(as: User.self)
                            user = snapshot
                            subscribersList.append(snapshot)
                        } catch {
                            print("error")
                        }
                    }
                }
            } else { // subscriptions
                if let index = subscriptionsList.firstIndex(where: { $0.id == cUid }) {
                    user = subscriptionsList[index]
                } else {
                    let ref = Firestore.firestore().collection("users").document(cUid)
                    Task {
                        do {
                            let snapshot = try await ref.getDocument(as: User.self)
                            user = snapshot
                            subscriptionsList.append(snapshot)
                        } catch {
                            print("error")
                        }
                    }
                }
            }
        }

    }
}
