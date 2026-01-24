import UIKit
import SwiftUI
import Social
import QuickLook

class ShareViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    private var downloadedURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup SwiftUI
        var shareView = ShareView(extensionContext: self.extensionContext)
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
            qlVC.delegate = self // Set delegate for cleanup
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
    
    // MARK: - QLPreviewControllerDelegate (Cleanup)
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        cleanUpTempFile()
    }
    
    private func cleanUpTempFile() {
        if let url = downloadedURL {
            try? FileManager.default.removeItem(at: url)
            print("[Share] Cleanup: Removed temp file at \(url.path)")
            self.downloadedURL = nil
        }
    }
    
    // Clean up
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cleanUpTempFile()
        // Cancel polling if active
        YTDLPManager.shared.cancel()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        cleanUpTempFile()
    }
}
