import UIKit
import SwiftUI
import Social
import QuickLook

class ShareViewController: UIViewController, QLPreviewControllerDataSource, QLPreviewControllerDelegate {

    private var downloadedURL: URL?
    private var viewModel: ShareViewModel! // Retain ViewModel

    override func loadView() {
        super.loadView()
        // Manually create the view since we are not using Storyboard
        self.view = UIView(frame: UIScreen.main.bounds)
        self.view.backgroundColor = .clear
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize ViewModel via parent controller
        self.viewModel = ShareViewModel(extensionContext: self.extensionContext)
        
        // Setup SwiftUI with hosting controller
        let shareView = ShareView(viewModel: self.viewModel)
        let hostingController = UIHostingController(rootView: shareView)
        
        // Ensure the main view is transparent to show the hosting controller content correctly
        view.backgroundColor = .clear
        
        // Proper child view controller lifecycle
        addChild(hostingController)
        hostingController.view.backgroundColor = .clear // Prevent flashes
        view.addSubview(hostingController.view)
        
        // Fallback for resizing
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
        
        // Force layout pass
        view.layoutIfNeeded()
        
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
    // MARK: - QLPreviewControllerDelegate (Cleanup)
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        cleanUpSession()
    }
    
    private func cleanUpSession() {
        // Strict cleanup: Delete the parent session directory of the file
        // Path structure: .../temp/session_<UUID>/output.mp4
        if let url = downloadedURL {
            let sessionDir = url.deletingLastPathComponent()
            do {
                try FileManager.default.removeItem(at: sessionDir)
                print("[Share] Cleanup: Removed session directory at \(sessionDir.path)")
            } catch {
                print("[Share] Cleanup Error: \(error)")
            }
            self.downloadedURL = nil
        }
        
        // Also trigger extension complete
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    // Clean up
    // Clean up handled in deinit to prevent premature closure
    // override func viewDidDisappear(_ animated: Bool) {
    //    super.viewDidDisappear(animated)
    // }
    
        deinit {
            // This deinit is called when the ShareViewController is deallocated.
            NotificationCenter.default.removeObserver(self)
            // cleanUpSession() - Removing to prevent premature extension closure.
            // Cleanup happens on QuickLook dismiss or startup GC.
        }}
