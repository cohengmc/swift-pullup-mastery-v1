//
//  ViewSharingUtilities.swift
//  pullup-mastery-v1
//
//  Created by Geoffrey Cohen on 10/31/25.
//

import SwiftUI
import UIKit
import LinkPresentation

// MARK: - View to Image Renderer
func renderViewAsImage<V: View>(view: V, size: CGSize = CGSize(width: 400, height: 400)) -> UIImage? {
    let controller = UIHostingController(rootView: view)
    let targetView = controller.view
    
    targetView?.bounds = CGRect(origin: .zero, size: size)
    targetView?.backgroundColor = .clear
    
    // Force layout
    targetView?.layoutIfNeeded()
    
    let renderer = UIGraphicsImageRenderer(size: size)
    
    return renderer.image { _ in
        targetView?.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
    }
}

// MARK: - Image Saver
class ImageSaver: NSObject {
    static let shared = ImageSaver()
    
    func saveImage(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error.localizedDescription)")
        } else {
            print("Image saved successfully")
        }
    }
}

// MARK: - Image Share Item
/// Provides rich preview metadata for images in the share sheet
class ImageShareItem: NSObject, UIActivityItemSource {
    var image: UIImage
    var title: String
    
    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
        super.init()
    }
    
    // Placeholder for the data
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image
    }
    
    // The actual data (the UIImage)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return image
    }
    
    // Subject line for email
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }
    
    // Rich preview metadata
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = self.title
        
        // Set the image provider
        let imageProvider = NSItemProvider(object: image)
        metadata.imageProvider = imageProvider
        
        return metadata
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

