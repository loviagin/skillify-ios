//
//  PointsViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/17/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class PointsViewModel: ObservableObject {
    @Published var gamePoints: [GamePoint] = []
    @Published var newDailyPoints = false
    
    init() {
        reload()
    }
    
    func reload() {
        Task {
            await loadPoints()
        }
    }
    
    func getSummaryPoints() -> Int {
        gamePoints.reduce(0) { $0 + $1.value }
    }
    
    //MARK: - Load all Game Points into self.gamePoints[]
    private func loadPoints() async {
        guard let user = Auth.auth().currentUser else { return }
        print("points")

        if let docs = try? await Firestore.firestore().collection("users").document(user.uid).collection("points").getDocuments(), !docs.isEmpty {
            // Очищаем массив gamePoints
            DispatchQueue.main.async {
                self.gamePoints.removeAll()
            }
            
            // Загружаем данные из Firestore
            for doc in docs.documents {
                if let point = try? doc.data(as: GamePoint.self) {
                    DispatchQueue.main.async {
                        self.gamePoints.append(point)
                    }
                }
            }
            
            // Дожидаемся завершения обновления массива gamePoints
            await MainActor.run {
                addDailyPoints() // Гарантируем, что массив gamePoints обновлён
            }
        }
    }
    
    private func addDailyPoints() {
        guard let user = Auth.auth().currentUser else { return }

        if gamePoints.first(where: {
            let calendar = Calendar.current
            return calendar.isDate($0.date, inSameDayAs: Date()) && $0.name == "Daily Talents"
        }) == nil {
            if newDailyPoints == false {
                let newPoint = GamePoint(name: "Daily Talents", value: 10)
                
                try? Firestore.firestore().collection("users").document(user.uid).collection("points").addDocument(from: newPoint)
                self.gamePoints.append(newPoint)
                self.newDailyPoints = true
            }
        }
    }
}
