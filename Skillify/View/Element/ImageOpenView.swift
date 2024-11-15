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
    var media: [String]
    @Binding var selectedImageIndex: Int

    @State private var scale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var temporaryOffset: CGSize = .zero
    @State private var showTools = true
    @State private var verticalDragOffset: CGFloat = 0.0
    @State private var dragThreshold: CGFloat = 150.0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedImageIndex) {
                ForEach(Array(media.enumerated()), id: \.offset) { index, element in
                    ZStack {
                        Color.black.ignoresSafeArea()

                        if let imageUrl = URL(string: element) {
                            KFImage(imageUrl)
                                .resizable()
                                .placeholder {
                                    ProgressView()
                                }
                                .cacheMemoryOnly()
                                .loadDiskFileSynchronously()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxHeight: .infinity - 40)
                                .scaleEffect(scale)
                                .offset(y: verticalDragOffset)  // Устанавливаем смещение для вертикального жеста
                                .simultaneousGesture(DragGesture(minimumDistance: 20, coordinateSpace: .local)
                                    .onChanged { value in
                                        // Проверяем, что жест двигается в вертикальном направлении
                                        if abs(value.translation.width) < abs(value.translation.height) {
                                            if value.translation.height > 0 {
                                                verticalDragOffset = value.translation.height
                                            }
                                        }
                                    }
                                    .onEnded { value in
                                        // Если смещение больше порога, закрываем представление
                                        if verticalDragOffset > dragThreshold {
                                            withAnimation {
                                                dismiss()
                                            }
                                        } else {
                                            // Если смещение меньше порога, возвращаем обратно
                                            withAnimation {
                                                verticalDragOffset = 0
                                            }
                                        }
                                    }
                                )
                                .simultaneousGesture(magnificationGesture.simultaneously(with: dragGesture))  // Поддержка зума и перетаскивания изображения
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
                    .tag(index)  // Используем индекс в качестве tag
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
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
        guard let url = URL(string: media[selectedImageIndex]) else {
            print("error not a link")
            return
        }

        // Используем Kingfisher для загрузки изображения по URL
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let value):
                let image = value.image
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
                    if value.translation.width < 0 {
                        if selectedImageIndex < media.count - 1 {
                            withAnimation {
                                selectedImageIndex += 1
                            }
                        }
                    } else if value.translation.width > 0 {
                        if selectedImageIndex > 0 {
                            withAnimation {
                                selectedImageIndex -= 1
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
