//
//  MainViewModel.swift
//  Learnsy
//
//  Created by Ilia Loviagin on 8/20/25.
//

import Foundation

class MainViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .home
    
    
}

enum AppTab {
    case home
}
