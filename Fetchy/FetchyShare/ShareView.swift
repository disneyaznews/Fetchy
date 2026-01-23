import SwiftUI
import UniformTypeIdentifiers

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    
    @State private var state: ShareState = .initial
    @State private var foundURL: URL?
    @State private var videoTitle: String = "Detecting..."
    @State private var progress: Double = 0.0
    @State private var downloadedFileURL: URL?
    @State private var showProgressOverride: Bool = false // User tapped to show
    
    enum ShareState {
        case initial
        case downloading
        case readyForPreview
        case error(String)
        case success // Post-preview
    }
    
    var body: some View {
        ZStack {
            // Background - Liquid Glass
            Color.clear
                .liquidGlass()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header / Initial Info
                if state != .readyForPreview {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.nothingRed)
                        
                        Text(videoTitle)
                            .font(.nothingHeader)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        DotMatrixText(text: stateText)
                    }
                    .padding()
                }
                
                // Progress Section (Hidden by default unless downloading & user requests, or logic enforces)
                if state == .downloading || showProgressOverride {
                    VStack {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.secondary.opacity(0.2))
                                
                                Capsule()
                                    .fill(DesignSystem.Colors.nothingRed)
                                    .frame(width: geo.size.width * progress)
                                    .animation(.spring, value: progress)
                            }
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text("\(Int(progress * 100))%")
                            Spacer()
                            if SettingsManager.shared.vibrationEnabled {
                                Image(systemName: "iphone.radiowaves.left.and.right")
                                    .font(.caption)
                            }
                        }
                        .font(.nothingMeta)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                } 
                else if state == .initial {
                    // "Show Progress" Button
                    Button(action: {
                        withAnimation {
                            showProgressOverride = true
                        }
                    }) {
                        HStack {
                            Text("SHOW PROGRESS")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(IndustrialButtonStyle())
                }
                
                // QuickLook / Open Section
                if case .readyForPreview = state, let fileURL = downloadedFileURL {
                    VStack(spacing: 16) {
                        Text("READY FOR PREVIEW")
                            .font(.nothingHeader)
                        
                        Button(action: {
                            openQuickLook(url: fileURL)
                        }) {
                            Label("Open Quick Look", systemImage: "eye")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(IndustrialButtonStyle())
                    }
                }
                
                // Error State
                if case .error(let msg) = state {
                     ToastView(message: msg, isWarning: true)
                }
            }
            .padding()
        }
        .onAppear {
            extractURL()
        }
    }
    
    // MARK: - Logic
    
    private var stateText: String {
        switch state {
        case .initial: return "ANALYZING INPUT..."
        case .downloading: return "DOWNLOADING..."
        case .readyForPreview: return "READY"
        case .error: return "FAILED"
        case .success: return "COMPLETED"
        }
    }
    
    private func extractURL() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { return }
        
        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                        if let url = item as? URL {
                            DispatchQueue.main.async {
                                self.foundURL = url
                                self.videoTitle = "URL Detected" // Better title fetching usually requires initial scrape
                                self.startDownload(url: url)
                            }
                        }
                    }
                    return
                }
                // Handle plain text that might be a URL
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                     provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
                        if let text = item as? String, let url = URL(string: text) { // Naive check
                             DispatchQueue.main.async {
                                self.foundURL = url
                                self.videoTitle = "Text Link"
                                self.startDownload(url: url)
                            }
                        }
                     }
                }
            }
        }
    }
    
    private func startDownload(url: URL) {
        state = .downloading
        
        YTDLPManager.shared.download(url: url.absoluteString, progressHandler: { prog in
            self.progress = prog
            // Haptic trigger could go here (every 2%)
        }) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fileURL):
                    self.downloadedFileURL = fileURL
                    self.state = .readyForPreview
                    // Save to DB history
                    let entry = VideoEntry(title: "Downloaded Video", url: url.absoluteString, service: "Share", status: .completed, localPath: fileURL.path)
                    DatabaseManager.shared.insert(entry: entry)
                    
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func openQuickLook(url: URL) {
        // In a real generic SwiftUI view, we might need a wrapper or bridge to QLPreviewController
        // relying on parent view controller integration. 
        // For this streamlined impl, we'll assume the parent `ShareViewController` handles the presentation
        // or we use a `quickLookPreview` modifier if available in newer iOS, 
        // OR we simply signal the parent.
        // For simplicity here:
        NotificationCenter.default.post(name: NSNotification.Name("OpenQuickLook"), object: url)
    }
}
