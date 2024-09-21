//
//  VideoChatPicker.swift
//  Skillify
//
//  Created by Ilia Loviagin on 9/7/24.
//

import SwiftUI
import PhotosUI

struct VideoChatPicker: UIViewControllerRepresentable {
    @Binding var selectedVideos: [URL]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos  // Только видео
        configuration.selectionLimit = 5  

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: VideoChatPicker

        init(_ parent: VideoChatPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            for result in results {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
                    guard let self = self, let url = url, error == nil else { return }

                    // Копируем видео в документы приложения
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let copiedURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)

                    if FileManager.default.fileExists(atPath: copiedURL.path) {
                        try? FileManager.default.removeItem(at: copiedURL)
                    }

                    try? FileManager.default.copyItem(at: url, to: copiedURL)

                    if self.parent.selectedVideos.count < 5 {
                        DispatchQueue.main.async {
                            self.parent.selectedVideos.append(copiedURL)
                        }
                    }
                }
            }
        }
    }
}
