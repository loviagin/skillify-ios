//
//  SubscribersViewModel.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 29.12.2023.
//

import Foundation


class SubscribersViewModel {
    
    enum SubscribersCategory: CaseIterable, Hashable {
        case subscribers, subscription
        
        var tabTitle: String {
            switch self {
            case .subscribers:
                return "Subscribers"
            case .subscription:
                return "Subscription"
            }
        }
    }
}
