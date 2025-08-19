//
//  VideoScrollModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import Foundation
import FirebaseFirestore

class VideoScrollModel: ObservableObject {
    @Published var videos: [Video] = []
    
    init() {
        loadVideos()
    }
    
    func update() {
        loadVideos()
    }
    
    private func loadVideos() {
        Firestore.firestore().collection("videos")
            .getDocuments { snap, error in
                if let error {
                    print(error)
                } else {
                    if let snap, !snap.isEmpty {
                        for item in snap.documents {
                            if let doc = try? item.data(as: Video.self) {
                                DispatchQueue.main.async {
                                    self.videos.append(doc)
                                }
                            } else {
                                print("incorrect video")
                            }
                        }
                    } else {
                        print("empty videos")
                    }
                }
            }
    }
}
