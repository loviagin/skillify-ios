//
//  VideCallView.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 02.03.2024.
//

import SwiftUI
import AgoraRtcKit

struct VideoCallView: UIViewControllerRepresentable {
    var callManager: CallManager
    
    func makeUIViewController(context: Context) -> VideoViewController {
        return VideoViewController(manager: callManager)
    }
    
    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {
        // Update UI if needed
        print("update ui view controller video")
    }
}

//import SwiftUI
//import AgoraRtcKit
//
//struct VideoCallView : UIViewControllerRepresentable {
//    var callManager: CallManager
//    
//    func makeUIViewController(context: Context) -> VideoViewController {
//        return VideoViewController(manager: callManager)
//    }
//    
//    func updateUIViewController(_ uiViewController: VideoViewController, context: Context) {
//        // Здесь можно обновить UI контроллер, если это необходимо
//        print("update ui view controller video")
//    }
//}
