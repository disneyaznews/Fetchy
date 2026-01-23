import UIKit
import SwiftUI
import Social
import QuickLook

class ShareViewController: UIViewController, QLPreviewControllerDataSource {

    private var downloadedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SwiftUI
        let shareView = ShareView(extensionContext: self.extensionContext)
        let hostingController = UIHostingController(rootView: shareView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Listen for QuickLook request
        NotificationCenter.default.addObserver(self, selector: #selector(handleQuickLookRequest(_:)), name: NSNotification.Name("OpenQuickLook"), object: nil)
    }
    
    @objc func handleQuickLookRequest(_ notification: Notification) {
        if let url = notification.object as? URL {
            self.downloadedURL = url
            let qlVC = QLPreviewController()
            qlVC.dataSource = self
            self.present(qlVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return downloadedURL != nil ? 1 : 0
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return downloadedURL! as QLPreviewItem
    }
    
    // Clean up
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Logic to complete extension request if finished?
        // self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Cleanup temp files if needed, though they are in temp directory
    }
}
