//
//  VideoThumbnailView.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/7/24.
//

import SwiftUI
import AVFoundation
import Kingfisher

struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnailImage: UIImage?

    var body: some View {
        if let thumbnailImage = thumbnailImage {
            Image(uiImage: thumbnailImage)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 15))
        } else {
            RoundedRectangle(cornerRadius: 15)
                .fill(.gray)
                .scaledToFit()
                .onAppear {
                    loadCachedThumbnail(for: videoURL)
                }
        }
    }

    private func loadCachedThumbnail(for url: URL) {
        // Создаем уникальный ключ для кэша на основе URL видео
        let cacheKey = url.absoluteString

        // Асинхронно проверяем, существует ли миниатюра в кэше
        KingfisherManager.shared.cache.retrieveImage(forKey: cacheKey) { result in
            switch result {
            case .success(let value):
                if let cachedImage = value.image {
                    DispatchQueue.main.async {
                        self.thumbnailImage = cachedImage
                    }
                } else {
                    // Если миниатюра отсутствует в кэше, генерируем её и сохраняем
                    generateThumbnail(for: url) { image in
                        if let image = image {
                            KingfisherManager.shared.cache.store(image, forKey: cacheKey)
                            DispatchQueue.main.async {
                                self.thumbnailImage = image
                            }
                        }
                    }
                }
            case .failure(let error):
                print("Ошибка при загрузке изображения из кэша: \(error)")
                generateThumbnail(for: url) { image in
                    if let image = image {
                        KingfisherManager.shared.cache.store(image, forKey: cacheKey)
                        DispatchQueue.main.async {
                            self.thumbnailImage = image
                        }
                    }
                }
            }
        }
    }

    private func generateThumbnail(for url: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 1, preferredTimescale: 60)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let uiImage = UIImage(cgImage: cgImage)
                completion(uiImage)
            } catch {
                print("Ошибка при генерации миниатюры: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
