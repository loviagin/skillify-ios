//
//  DocumentSaver.swift
//  Skillify App
//
//  Created by Ilia Loviagin on 11.03.2024.
//
//import SwiftUI
//import UIKit
//
//struct DocumentSaver: UIViewControllerRepresentable {
//    var fileURL: URL
//    var onPick: (URL) -> Void
//    
//    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
//        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
//        picker.delegate = context.coordinator
//        return picker
//    }
//    
//    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//    
//    class Coordinator: NSObject, UIDocumentPickerDelegate {
//        var parent: DocumentSaver
//        
//        init(parent: DocumentSaver) {
//            self.parent = parent
//        }
//        
//        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//            guard let folderURL = urls.first else { return }
//            parent.onPick(folderURL)
//        }
//    }
//}
