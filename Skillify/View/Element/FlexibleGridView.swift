//
//  FlexibleGridView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/29/24.
//


import SwiftUI
import Kingfisher

struct FlexibleGridView: View {
    var media: [String]

    @State private var showFullScreen = false
    @State private var selectedImageIndex: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let spacing: CGFloat = 5
            
            switch media.count {
            case 1:
                Button {
                    selectedImageIndex = 0
                    showFullScreen = true
                } label: {
                    KFImage(URL(string: media[0]))
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            case 2:
                HStack(spacing: spacing) {
                    ForEach(Array(media.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            selectedImageIndex = index
                            showFullScreen = true
                        } label: {
                            KFImage(URL(string: urlString))
                                .resizable()
                                .scaledToFill()
                                .frame(width: (size.width - spacing) / 2, height: (size.height - spacing))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                    }
                }
                
            case 3:
                VStack(spacing: spacing) {
                    Button {
                        selectedImageIndex = 0
                        showFullScreen = true
                    } label: {
                        KFImage(URL(string: media[0]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height * 2 / 3)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                    
                    HStack(spacing: spacing) {
                        Button {
                            selectedImageIndex = 1
                            showFullScreen = true
                        } label: {
                            KFImage(URL(string: media[1]))
                                .resizable()
                                .scaledToFill()
                                .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                        
                        Button {
                            selectedImageIndex = 2
                            showFullScreen = true
                        } label: {
                            KFImage(URL(string: media[2]))
                                .resizable()
                                .scaledToFill()
                                .frame(width: (size.width - spacing) / 2, height: (size.height / 3))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                    }
                }
                
            case 4:
                let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
                
                LazyVGrid(columns: gridItems, spacing: spacing) {
                    ForEach(Array(media.enumerated()), id: \.offset) { index, urlString in
                        Button {
                            selectedImageIndex = index
                            showFullScreen = true
                        } label: {
                            KFImage(URL(string: urlString))
                                .resizable()
                                .scaledToFill()
                                .frame(width: (size.width - spacing) / 2, height: (size.height - spacing) / 2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                    }
                }
                
            case 5:
                VStack(spacing: spacing) {
                    Button {
                        selectedImageIndex = 0
                        showFullScreen = true
                    } label: {
                        KFImage(URL(string: media[0]))
                            .resizable()
                            .scaledToFill()
                            .frame(width: size.width, height: size.height / 2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .clipped()
                    }
                    
                    let gridItems = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
                    
                    LazyVGrid(columns: gridItems, spacing: spacing) {
                        ForEach(Array(media[1...4].enumerated()), id: \.offset) { index, urlString in
                            Button {
                                selectedImageIndex = index + 1
                                showFullScreen = true
                            } label: {
                                KFImage(URL(string: urlString))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (size.width - spacing) / 2, height: (size.height / 4))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .clipped()
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
            ImageOpenView(media: media, selectedImageIndex: $selectedImageIndex)
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

