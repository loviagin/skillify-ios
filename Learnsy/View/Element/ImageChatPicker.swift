//
//  ImagePicker.swift
//  Skillify
//
//  Created by Ilia Loviagin on 8/28/24.
//

import SwiftUI
import PhotosUI

struct ImageChatPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 5
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImageChatPicker

        init(_ parent: ImageChatPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    guard let self = self, let uiImage = image as? UIImage, error == nil else { return }
                    DispatchQueue.main.async {
                        if self.parent.selectedImages.count < 5 {
                            self.parent.selectedImages.append(uiImage)
                        }
                    }
                }
            }
        }
    }
}
