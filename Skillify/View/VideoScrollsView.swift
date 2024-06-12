//
//  VideoScrollsView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 6/12/24.
//

import SwiftUI

struct VideoScrollsView: View {
    @StateObject private var viewModel = VideoScrollModel()
    
    @State var currentVideo: String = ""
    
    var body: some View {
        if !viewModel.videos.isEmpty {
            TabView(selection: $currentVideo) {
                ForEach(viewModel.videos, id: \.id) { it in
                    VideoView(url: it.url)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onAppear {
                if viewModel.videos.count >= 1 && currentVideo.isEmpty {
                    self.currentVideo = viewModel.videos.first!.id
                }
            }
            .refreshable {
                viewModel.update()
            }
        }
    }
}

#Preview {
    VideoScrollsView()
}
