//
//  SubscriptionManager.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/9/25.
//

import Foundation
import Combine

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @Published var subscriptions: Set<String> = []
    
    private init() {
        loadSubscriptions()
    }
    
    // MARK: - Public Methods
    func isSubscribed(to userId: String) -> Bool {
        return subscriptions.contains(userId)
    }
    
    func toggleSubscription(to userId: String) {
        if subscriptions.contains(userId) {
            subscriptions.remove(userId)
        } else {
            subscriptions.insert(userId)
        }
        saveSubscriptions()
    }
    
    func subscribe(to userId: String) {
        subscriptions.insert(userId)
        saveSubscriptions()
    }
    
    func unsubscribe(from userId: String) {
        subscriptions.remove(userId)
        saveSubscriptions()
    }
    
    // MARK: - Persistence
    private func loadSubscriptions() {
        if let data = UserDefaults.standard.data(forKey: "user_subscriptions"),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            subscriptions = decoded
        }
    }
    
    private func saveSubscriptions() {
        if let encoded = try? JSONEncoder().encode(subscriptions) {
            UserDefaults.standard.set(encoded, forKey: "user_subscriptions")
        }
    }
}
