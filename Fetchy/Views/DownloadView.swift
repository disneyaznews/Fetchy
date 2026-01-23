import SwiftUI

struct DownloadView: View {
    @State private var urlInput: String = ""
    @State private var isDownloading = false
    @State private var progress: Double = 0.0
    @State private var statusMessage: String = "READY"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    
                    // Input Section
                    VStack(alignment: .leading, spacing: 8) {
                        DotMatrixText(text: "TARGET URL")
                        
                        TextField("Paste Link Here...", text: $urlInput)
                            .padding()
                            .background(Color.white.opacity(0.5)) // Slightly more opaque for input
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.primary.opacity(0.1))
                            )
                            .submitLabel(.go)
                            .onSubmit {
                                startDownload()
                            }
                    }
                    .padding(.horizontal)
                    
                    // Progress & Status
                    if isDownloading {
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
                    }
                    
                    Spacer()
                    
                    // Action Button
                    Button(action: startDownload) {
                        Text("INITIATE SEQUENCE")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(IndustrialButtonStyle())
                    .disabled(urlInput.isEmpty || isDownloading)
                    .padding()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Download")
        }
    }
    
    private func startDownload() {
        guard !urlInput.isEmpty else { return }
        isDownloading = true
        statusMessage = "INITIALIZING..."
        progress = 0.0
        
        // Use YTDLPManager
        YTDLPManager.shared.download(url: urlInput, progressHandler: { prog in
            self.progress = prog
            self.statusMessage = "DOWNLOADING..."
        }) { result in
            DispatchQueue.main.async {
                self.isDownloading = false
                switch result {
                case .success(_):
                    self.statusMessage = "COMPLETED"
                    self.urlInput = ""
                case .failure(let error):
                    self.statusMessage = "ERROR: \(error.localizedDescription)"
                }
            }
        }
    }
}
