//
//  VideoViewController.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 02.03.2024.
//

import UIKit
import AgoraRtcKit

class VideoViewController: UIViewController {
    var manager: CallManager
    let localVideo = UIView()
    let remoteVideo = UIView()
    
    init(manager: CallManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil) // Вызовите здесь обозначенный инициализатор `UIViewController`
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(localVideo)
        view.addSubview(remoteVideo)
        setupLocalVideo()
    }

    func setupLocalVideo() {
        manager.agoraManager.agoraKit.enableVideo()  // Включаем видео
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = localVideo
        videoCanvas.renderMode = .fit
        manager.agoraManager.agoraKit.setupLocalVideo(videoCanvas)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        remoteVideo.frame = view.bounds // Удаленное видео на весь экран

        // Задаем размер и положение для localVideo
        let localVideoSize = CGSize(width: view.frame.width / 4, height: view.frame.height / 4)
        localVideo.frame = CGRect(
            x: view.frame.width - localVideoSize.width - 20,
            y: view.frame.height - localVideoSize.height - 150,
            width: localVideoSize.width,
            height: localVideoSize.height)

        view.bringSubviewToFront(localVideo) // Перемещаем localVideo на передний план
    }
    
    func setup() {
        
    }
}

//extension VideoViewController: AgoraRtcEngineDelegate {
//    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
//        print("я запускаю видео юхуу")
//        DispatchQueue.main.async { [weak self] in
//            
//            guard let strongSelf = self else { return }
//            let remoteCanvas = AgoraRtcVideoCanvas()
//            remoteCanvas.uid = uid
//            remoteCanvas.view = strongSelf.remoteVideo
//            remoteCanvas.renderMode = .fit
//            strongSelf.agoraKit.setupRemoteVideo(remoteCanvas)
//        }
//    }
//}
//
