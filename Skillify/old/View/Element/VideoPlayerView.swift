//
//  VideoPlayerView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/7/24.
//

import SwiftUI
import AVFoundation
import AVKit

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player = AVPlayer()

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
                player.play()
            }
            .onDisappear {
                player.pause()
            }
    }
}
