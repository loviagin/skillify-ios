//
//  FirestoreUpdater.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 26.12.2023.
//

import Foundation
import FirebaseFirestore

class FirestoreUpdater {
    static func updateUsersWithBio() {
        let db = Firestore.firestore()
        db.collection("messages").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    document.reference.updateData([
                        "id": document.documentID // Здесь установите нужное значение
                    ])
                }
            }
        }
    }
}
//class FirestoreUpdater {
//    static func updateUsersWithBio() {
//        let db = Firestore.firestore()
//        db.collection("messages").getDocuments { (querySnapshot, err) in
//            if let err = err {
//                print("Error getting documents: \(err)")
//            } else {
//                for document in querySnapshot!.documents {
//                    // Проверяем, есть ли у документа поле messages и является ли оно массивом
//                    if var messages = document.data()["messages"] as? [[String: Any]] {
//                        // Итерируем через каждое сообщение в массиве, чтобы добавить новые поля
//                        for index in 0..<messages.count {
//                            // Здесь добавляем новые поля к каждому сообщению
//                            // Пример добавления поля "newField" со значением "newValue"
////                            messages[index]["id"] = UUID().uuidString
////                            messages[index]["status"] = "r"
//                            messages[index]["emoji"] = nil
////                            messages[index]["replyTo"] = nil
//                            // Добавляйте столько полей, сколько вам нужно, по аналогии выше
//                        }
//                        
//                        // Обновляем документ с новым массивом messages
//                        document.reference.updateData(["messages": messages]) { err in
//                            if let err = err {
//                                print("Error updating document: \(err)")
//                            } else {
//                                print("Document successfully updated")
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
