//
//  AudioPlayerCoordinator.swift
//  Skillify
//
//  Created by Ilia Loviagin on 10/17/24.
//

import Foundation
import AVFoundation

class AudioPlayerCoordinator: NSObject, AVAudioPlayerDelegate {
    var onFinishPlaying: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Когда аудиоплеер завершает воспроизведение
        onFinishPlaying?()
    }
}
