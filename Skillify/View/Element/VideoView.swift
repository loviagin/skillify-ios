//
//  VideoView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import SwiftUI
import AVKit

struct VideoView: View {
    var url: String
    var player: AVPlayer?
    
    init(url: String) {
        self.url = url
        if let url = URL(string: url) {
            player = AVPlayer(url: url)
        }
    }
    
    var body: some View {
        if let player {
            VideoPlayer(player: player)
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
        } else {
            ProgressView()
        }
    }
}
