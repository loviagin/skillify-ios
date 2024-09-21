//
//  FlexibleVideoView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/7/24.
//

import SwiftUI
import AVKit

struct FlexibleVideoView: View {
    var media: [String]  // URL-адреса видео

    @State private var showFullScreen = false
    @State private var selectedVideoIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let spacing: CGFloat = 5

            switch media.count {
            case 1:
                Button {
                    selectedVideoIndex = 0
                    showFullScreen = true
                } label: {
                    VideoThumbnailView(videoURL: URL(string: media[0])!)  // Показ миниатюры видео
                        .frame(width: size.width, height: size.height)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            case 2:
                HStack(spacing: spacing) {
                    ForEach(Array(media.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            selectedVideoIndex = index
                            showFullScreen = true
                        } label: {
                            VideoThumbnailView(videoURL: URL(string: urlString)!)
                                .frame(width: (size.width - spacing) / 2, height: (size.height - spacing) / 2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

            case 3:
                VStack(spacing: spacing) {
                    Button {
                        selectedVideoIndex = 0
                        showFullScreen = true
                    } label: {
                        VideoThumbnailView(videoURL: URL(string: media[0])!)
                            .frame(width: size.width, height: size.height * 2 / 3)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    HStack(spacing: spacing) {
                        Button {
                            selectedVideoIndex = 1
                            showFullScreen = true
                        } label: {
                            VideoThumbnailView(videoURL: URL(string: media[1])!)
                                .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        Button {
                            selectedVideoIndex = 2
                            showFullScreen = true
                        } label: {
                            VideoThumbnailView(videoURL: URL(string: media[2])!)
                                .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

            case 4:
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)

                LazyVGrid(columns: gridItems, spacing: spacing) {
                    ForEach(Array(media.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            selectedVideoIndex = index
                            showFullScreen = true
                        } label: {
                            VideoThumbnailView(videoURL: URL(string: urlString)!)
                                .frame(width: (size.width - spacing) / 2, height: (size.height - spacing) / 2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

            case 5:
                VStack(spacing: spacing) {
                    Button {
                        selectedVideoIndex = 0
                        showFullScreen = true
                    } label: {
                        VideoThumbnailView(videoURL: URL(string: media[0])!)
                            .frame(width: size.width, height: size.height / 2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)

                    LazyVGrid(columns: gridItems, spacing: spacing) {
                        ForEach(Array(media[1...4].enumerated()), id: \.offset) { index, urlString in
                            Button {
                                selectedVideoIndex = index + 1
                                showFullScreen = true
                            } label: {
                                VideoThumbnailView(videoURL: URL(string: urlString)!)
                                    .frame(width: (size.width - spacing) / 2, height: (size.height / 4))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                }

            default:
                EmptyView()
            }
        }
        .frame(height: calculateHeight(for: media.count, width: UIScreen.main.bounds.width - 80))
        .fullScreenCover(isPresented: $showFullScreen) {
            VideoOpenView(media: media, selectedVideoIndex: $selectedVideoIndex)
        }
    }

    private func calculateHeight(for count: Int, width: CGFloat) -> CGFloat {
        let spacing: CGFloat = 5

        switch count {
        case 1:
            return width
        case 2:
            return (width / 2)
        case 3:
            return (width * 2 / 3) + (width / 3) + spacing
        case 4:
            return (width / 2) * 2 + spacing
        case 5:
            return (width / 2) + ((width / 4) * 2) + spacing
        default:
            return 0
        }
    }
}
