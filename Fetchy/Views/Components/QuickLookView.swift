import SwiftUI
import QuickLook

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        
        // Wrap in NavigationController to ensure toolbar/share button visibility
        let nav = UINavigationController(rootViewController: controller)
        return nav
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let parent: QuickLookView
        
        init(parent: QuickLookView) {
            self.parent = parent
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }
        
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return PreviewItem(url: parent.url)
        }
    }
}

class PreviewItem: NSObject, QLPreviewItem {
    let previewItemURL: URL?
    let previewItemTitle: String?
    
    init(url: URL) {
        self.previewItemURL = url
        self.previewItemTitle = url.lastPathComponent
        super.init()
        
        // Start accessing if it's a file URL (App Group safety)
        if url.isFileURL {
            _ = url.startAccessingSecurityScopedResource()
        }
    }
    
    deinit {
        if let url = previewItemURL, url.isFileURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
