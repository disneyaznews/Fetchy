import SwiftUI
import UniformTypeIdentifiers

struct ShareView: View {
    var extensionContext: NSExtensionContext?
    
    @State private var state: ShareState = .initial
    @State private var foundURL: URL?
    @State private var videoTitle: String = "Detecting..."
    @State private var progress: Double = 0.0
    @State private var downloadedFileURL: URL?
    @State private var selectedResolution: String = "1080p"
    
    enum ShareState: Equatable {
        case initial
        case downloading
        case readyForPreview
        case error(String)
        case success
    }
    
    @State private var statusMessage: String = "ANALYZING..."
    @State private var lastHapticProgress: Double = 0.0
    @State private var startTime: Date?
    @State private var toastMessage: String?
    @State private var isShowingToast = false
    
    let resolutions = ["2160p", "1080p", "720p", "480p"]
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            Color.clear
                .liquidGlass()
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if state == .initial {
                    VStack(spacing: 20) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(DesignSystem.Colors.nothingRed)
                        
                        Text("LINK DETECTED")
                            .font(.nothingHeader)
                        
                        // Resolution Selection
                        VStack(alignment: .leading, spacing: 8) {
                            DotMatrixText(text: "QUALITY PREFERENCE")
                            
                            HStack {
                                ForEach(resolutions, id: \.self) { res in
                                    Button(action: { selectedResolution = res }) {
                                        Text(res)
                                            .font(.nothingMeta)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedResolution == res ? DesignSystem.Colors.nothingRed : Color.secondary.opacity(0.1))
                                            .foregroundColor(selectedResolution == res ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            if let url = foundURL {
                                startDownload(url: url)
                            }
                        }) {
                            Text("START DOWNLOAD")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(IndustrialButtonStyle())
                        .disabled(foundURL == nil)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: state == .downloading ? "arrow.down.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(state == .downloading ? DesignSystem.Colors.nothingRed : .green)
                            .symbolEffect(.pulse, isActive: state == .downloading)
                        
                        Text(videoTitle)
                            .font(.nothingHeader)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        DotMatrixText(text: stateText)
                        
                        if state == .downloading {
                            VStack(spacing: 8) {
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
                                
                                Text("\(Int(progress * 100))%")
                                    .font(.nothingMeta)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 10)
                        }
                    }
                    .padding()
                }
                
                if case .readyForPreview = state, let fileURL = downloadedFileURL {
                    Button(action: { openQuickLook(url: fileURL) }) {
                        Label("RE-OPEN PREVIEW", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(IndustrialButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding()
            
            // Toast layer
            if isShowingToast, let msg = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: msg)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            extractURL()
        }
    }
    
    private var stateText: String {
        switch state {
        case .initial: return "READY"
        case .downloading: return "DOWNLOADING..."
        case .readyForPreview: return "COMPLETED"
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
                                self.videoTitle = url.host ?? "External Link"
                            }
                        }
                    }
                    return
                }
            }
        }
    }
    
    private func startDownload(url: URL) {
        state = .downloading
        startTime = Date()
        
        YTDLPManager.shared.download(url: url.absoluteString, quality: selectedResolution, statusHandler: { prog, status in
            DispatchQueue.main.async {
                if prog >= 0 {
                    self.progress = prog
                    checkHaptics(prog)
                }
                self.statusMessage = status
                checkTimeWarnings()
            }
        }) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (fileURL, log)):
                    self.downloadedFileURL = fileURL
                    self.state = .readyForPreview
                    self.progress = 1.0
                    
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    let entry = VideoEntry(
                        title: fileURL.lastPathComponent,
                        url: url.absoluteString,
                        service: url.host ?? "Unknown",
                        status: .completed,
                        localPath: fileURL.path
                    )
                    DatabaseManager.shared.insert(entry: entry, rawLog: log)
                    
                    // Auto-open QuickLook
                    openQuickLook(url: fileURL)
                    
                case .failure(let error):
                    self.showToast(error.localizedDescription)
                    self.state = .error(error.localizedDescription)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
    
    private func checkHaptics(_ prog: Double) {
        if SettingsManager.shared.vibrationEnabled {
            if prog >= lastHapticProgress + 0.05 {
                hapticGenerator.impactOccurred()
                lastHapticProgress = prog
            }
        }
    }
    
    private func checkTimeWarnings() {
        guard SettingsManager.shared.toastEnabled else { return }
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        
        if elapsed > 480 {
            showToast("OSにより中断される可能性があります。")
        }
    }
    
    private func showToast(_ message: String) {
        toastMessage = message
        withAnimation { isShowingToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { isShowingToast = false }
        }
    }
    
    private func openQuickLook(url: URL) {
        NotificationCenter.default.post(name: NSNotification.Name("OpenQuickLook"), object: url)
    }
}

