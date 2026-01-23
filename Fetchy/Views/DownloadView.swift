import SwiftUI
import QuickLook

struct DownloadView: View {
    @ObservedObject var settings = SettingsManager.shared
    @State private var urlInput: String = ""
    @State private var isDownloading = false
    @State private var progress: Double = 0.0
    @State private var statusMessage: String = "READY"
    @State private var showProgress = false
    @State private var selectedResolution: String = "1080p"
    
    // QuickLook support
    @State private var previewURL: URL?
    @State private var showPreview = false
    
    let resolutions = ["2160p", "1080p", "720p", "480p", "360p"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        DotMatrixText(text: "TARGET URL")
                        
                        TextField("Paste Link Here...", text: $urlInput)
                            .padding()
                            .liquidGlass()
                            .submitLabel(.go)
                            .onSubmit {
                                startDownload()
                            }
                        
                        // Resolution Selection
                        VStack(alignment: .leading, spacing: 8) {
                            DotMatrixText(text: "QUALITY PREFERENCE")
                            
                            HStack {
                                ForEach(resolutions.prefix(4), id: \.self) { res in
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
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    
                    // Progress & Status
                    if isDownloading && (showProgress || settings.progressVisible) {
                        VStack(spacing: 12) {
                            DotMatrixText(text: statusMessage)
                            
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
                        }
                        .padding()
                        .liquidGlass()
                        .padding(.horizontal)
                    } else if isDownloading {
                        Button(action: { showProgress = true }) {
                            HStack {
                                Text("SHOW PROGRESS")
                                Image(systemName: "percent")
                            }
                            .font(.nothingMeta)
                        }
                        .buttonStyle(IndustrialButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Action Button
                    Button(action: startDownload) {
                        Text(isDownloading ? "SEQUENCE IN PROGRESS" : "INITIATE SEQUENCE")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(IndustrialButtonStyle())
                    .disabled(urlInput.isEmpty || isDownloading)
                    .padding()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Download")
            .sheet(isPresented: $showPreview) {
                if let url = previewURL {
                    QuickLookView(url: url)
                }
            }
        }
    }
    
    private func startDownload() {
        guard !urlInput.isEmpty else { return }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        isDownloading = true
        statusMessage = "INITIALIZING..."
        progress = 0.0
        
        YTDLPManager.shared.download(url: urlInput, quality: selectedResolution, statusHandler: { prog, status in
            DispatchQueue.main.async {
                if prog >= 0 {
                    self.progress = prog
                }
                self.statusMessage = status.uppercased()
            }
        }) { result in
            DispatchQueue.main.async {
                self.isDownloading = false
                switch result {
                case .success(let (fileURL, log)):
                    self.statusMessage = "COMPLETED"
                    self.progress = 1.0
                    
                    // Success Haptic
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    // Save to database
                    let entry = VideoEntry(
                        title: fileURL.lastPathComponent,
                        url: self.urlInput,
                        service: "Direct",
                        status: .completed,
                        localPath: fileURL.path
                    )
                    DatabaseManager.shared.insert(entry: entry, rawLog: log)
                    
                    // Trigger Preview
                    self.previewURL = fileURL
                    self.showPreview = true
                    
                    self.urlInput = ""
                case .failure(let error):
                    self.statusMessage = "ERROR: \(error.localizedDescription)"
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
        }
    }
}

// QuickLook SwiftUI Wrapper
struct QuickLookView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
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
            return parent.url as QLPreviewItem
        }
    }
}

