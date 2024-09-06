//
//  ImageOpenView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/29/24.
//

import SwiftUI
import Kingfisher

struct ImageOpenView: View {
    @Environment(\.dismiss) private var dismiss
    var media: [String]  // Массив URL-адресов изображений
    @State var selection: String
    
    @State private var scale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var temporaryOffset: CGSize = .zero
    @State private var showTools = true
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {
                ForEach(media, id: \.self) { url in
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        if let imageUrl = URL(string: url) {
                            KFImage(imageUrl)
                                .resizable()
                                .placeholder {
                                    ProgressView()
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: .infinity - 40)
                                .scaleEffect(scale)
                                .offset(scale != 1.0 ? currentOffset : .zero)
                                .gesture(magnificationGesture.simultaneously(with: dragGesture))
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        if scale == 1.0 {
                                            scale = 4.0
                                        } else {
                                            scale = 1.0
                                        }
                                        currentOffset = .zero
                                        temporaryOffset = .zero
                                    }
                                }
                                .onTapGesture(count: 1) {
                                    withAnimation {
                                        showTools.toggle()
                                    }
                                }
                                .scaledToFit()
                        } else {
                            Text("Unable to load image")
                                .foregroundColor(.white)
                                .onTapGesture {
                                    dismiss()
                                }
                        }
                    }
                    .tag(url)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .onAppear {
                print("selection \(selection) in \(media.compactMap({ $0 }))")
            }
            .toolbar {
                if showTools {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                downloadImage()
                            } label: {
                                Label("Save to gallery", systemImage: "arrow.down.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "arrow.backward")
                                .resizable()
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .toolbarBackground(showTools ? .visible : .hidden, for: .navigationBar)
        }
    }
    
    private func downloadImage() {
        guard let url = URL(string: selection) else {
            print("error not a link")
            return
        }
        
        // Используем Kingfisher для загрузки изображения по URL
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let value):
                // Получаем UIImage из результата загрузки
                let image = value.image
                // Сохраняем изображение в галерею
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                print("Image saved to gallery")
            case .failure(let error):
                print("Error downloading image: \(error)")
            }
        }
    }
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1.0, value.magnitude)
            }
    }
    
    var dragGesture: some Gesture {
            DragGesture()
                .onChanged { value in
                    if scale == 1.0 {
                        currentOffset = CGSize(width: value.translation.width + temporaryOffset.width, height: value.translation.height + temporaryOffset.height)
                    } else {
                        currentOffset = CGSize(width: value.translation.width + temporaryOffset.width, height: value.translation.height + temporaryOffset.height)
                    }
                }
                .onEnded { value in
                    if scale == 1.0 && abs(value.translation.width) > 50 {
                        let currentIndex = media.firstIndex(of: selection) ?? 0
                        if value.translation.width < 0 {
                            if currentIndex < media.count - 1 {
                                withAnimation {
                                    selection = media[currentIndex + 1]
                                }
                            }
                        } else if value.translation.width > 0 {
                            if currentIndex > 0 {
                                withAnimation {
                                    selection = media[currentIndex - 1]
                                }
                            }
                        }
                    } else {
                        temporaryOffset = currentOffset
                    }
                    
                    withAnimation {
                        if scale == 1.0 {
                            currentOffset = .zero
                            temporaryOffset = .zero
                        }
                    }
                }
        }
}
