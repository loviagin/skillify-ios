//
//  MainViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/5/25.
//

import Foundation

class MainViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .home
}

enum AppTab {
    case home, discover, account
}

extension MainViewModel {
    static var mock: MainViewModel {
        let viewModel = MainViewModel()
        return viewModel
    }
}
