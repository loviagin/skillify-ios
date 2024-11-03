//
//  CoursesViewModel.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import Foundation
import FirebaseFirestore
import AVFoundation
import UIKit

class CoursesViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var videos: [Video] = []
    
    init() {
        loadVideos()
        loadCourses()
    }
    
    private func loadVideos() {
        Firestore.firestore().collection("videos").getDocuments { snap, error in
            if let error {
                print(error)
            } else {
                if let snap, !snap.isEmpty {
                    for item in snap.documents {
                        if let doc = try? item.data(as: Video.self) {
                            DispatchQueue.main.async {
                                self.videos.append(doc)
                            }
                            print("added video on Courses")
                        }
                    }
                }
            }
        }
    }
    
    func getThumbnailFromVideo(videoURL: String, atTime time: CMTime = CMTime(seconds: 1, preferredTimescale: 600)) -> UIImage? {
        if let url = URL(string: videoURL) {
            let asset = AVAsset(url: url)
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                return thumbnail
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                return nil
            }
        } else {
            return nil
        }
    }
    
    private func loadCourses() {
        print("load courses TODO")
    }
}

extension CoursesViewModel {
    static var mock: CoursesViewModel {
        let viewModel = CoursesViewModel()
        return viewModel
    }
}
