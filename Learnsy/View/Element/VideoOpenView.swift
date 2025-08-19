//
//  VideoOpenView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/7/24.
//

import SwiftUI
import AVKit

struct VideoOpenView: View {
    var media: [String]  // Массив URL-адресов видео
    @Binding var selectedVideoIndex: Int
    @Environment(\.dismiss) private var dismiss  // Для закрытия полноэкранного представления

    @State private var offset: CGFloat = 0.0
    @State private var isDragging = false

    var body: some View {
        NavigationView {
            ZStack {
                VideoPlayerView(videoURL: URL(string: media[selectedVideoIndex])!)
                    .ignoresSafeArea()
                    .offset(y: offset)  // Смещаем видео при свайпе
                    .simultaneousGesture(
                        DragGesture()
                            .onChanged { gesture in
                                // Смещаем видео вниз во время свайпа
                                if gesture.translation.height > 0 {
                                    offset = gesture.translation.height
                                    isDragging = true
                                }
                            }
                            .onEnded { gesture in
                                if gesture.translation.height > 150 {
                                    // Закрываем, если свайп был достаточно сильным
                                    withAnimation {
                                        dismiss()
                                    }
                                } else {
                                    // Возвращаем видео в исходное положение, если свайп был недостаточно сильным
                                    withAnimation {
                                        offset = 0
                                        isDragging = false
                                    }
                                }
                            }
                    )
                    .navigationBarItems(leading: Button("Close") {
                        withAnimation {
                            dismiss()
                        }
                    })
            }
            .animation(.easeInOut, value: offset)  // Анимация для плавного движения
        }
    }
}
