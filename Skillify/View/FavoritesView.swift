//
//  FavoritesView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 03.02.2024.
//

import SwiftUI

struct FavoritesView: View {
    @State var selection: FavoritesViewModel.FavoritesEnum = .users
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var favoritesViewModel = FavoritesViewModel()
    @StateObject var activeSkillManager = ActiveSkillManager()
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Your favorites")
                .font(.title)
                .padding(.horizontal)
            Picker("Select favorites type", selection: $selection) {
                Text("Users")
                    .tag(FavoritesViewModel.FavoritesEnum.users)
                Text("Groups")
                    .tag(FavoritesViewModel.FavoritesEnum.groups)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selection) { _, _ in
                favoritesViewModel.selection = selection
                Task {
                    await favoritesViewModel.work()
                }
            }
            switch selection {
            case .users:
                if !authViewModel.currentUser!.favorites.filter({$0.type == "user"}).isEmpty {
                    ForEach(favoritesViewModel.favoritesUsers) { item in
                        UserCardView(user: item, authViewModel: authViewModel, activeSkillManager: activeSkillManager, id: authViewModel.currentUser!.id)
                            .foregroundColor(.primary)
                            .padding()
                    }
                } else {
                    EmptyFavoritesView(text: "users")
                }
            case .groups:
                if let list = authViewModel.currentUser?.favorites.filter({$0.type == "groups"}) {
                    ForEach(favoritesViewModel.favoritesUGroups) { item in
                        Text("will be soon")
                    }
                } else {
                    EmptyFavoritesView(text: "groups")
                }
            }
            Spacer()
        }
        .onAppear {
            favoritesViewModel.authViewModel = authViewModel
            Task {
                await favoritesViewModel.work()
            }
        }
    }
}

//#Preview {
//    FavoritesView(isTabViewShow: .constant(true))
//}

struct EmptyFavoritesView: View {
    var text: String
    var body: some View {
        Text("You don't have any favorites \(text)")
            .font(.title3)
            .padding()
        Spacer()
    }
}
