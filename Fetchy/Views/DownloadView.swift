import SwiftUI

struct DownloadView: View {
    @State private var urlInput: String = ""
    @State private var selectedResolution: String = "1080p"
    @State private var isAudioOnly: Bool = false
    @State private var selectedFormat: String = "mp4"
    @State private var selectedBitrate: String = "192"
    
    let videoResolutions = ["2160p", "1080p", "720p", "480p"]
    let videoFormats = ["mp4", "webm", "mkv"]
    let audioFormats = ["mp3", "m4a", "wav"]
    let audioBitrates = ["320", "256", "192", "128"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                
                VStack(spacing: 16) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            DotMatrixText(text: "TARGET URL")
                            Spacer()
                            if !urlInput.isEmpty {
                                Button(action: { urlInput = "" }) {
                                    Text("RESET")
                                        .font(.nothingMeta)
                                        .foregroundColor(DesignSystem.Colors.nothingRed)
                                }
                            }
                        }
                        
                        TextField("Paste Link Here...", text: $urlInput)
                            .padding()
                            .liquidGlass()
                            .submitLabel(.go)
                            .onSubmit {
                                startDownload()
                            }
                        
                        // Mode Toggle (Video/Audio)
                        HStack(spacing: 12) {
                            modeButton(title: "VIDEO", isActive: !isAudioOnly) {
                                withAnimation { isAudioOnly = false; selectedFormat = "mp4" }
                            }
                            modeButton(title: "AUDIO", isActive: isAudioOnly) {
                                withAnimation { isAudioOnly = true; selectedFormat = "mp3" }
                            }
                        }
                        .padding(.top, 4)
                        
                        // Dynamic Pickers
                        if isAudioOnly {
                            pickerSection(title: "AUDIO FORMAT", items: audioFormats, selection: $selectedFormat)
                            pickerSection(title: "BITRATE (kbps)", items: audioBitrates, selection: $selectedBitrate)
                        } else {
                            pickerSection(title: "RESOLUTION", items: videoResolutions, selection: $selectedResolution)
                            pickerSection(title: "CONTAINER", items: videoFormats, selection: $selectedFormat)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Button
                    Button(action: startDownload) {
                        Text("INITIATE DOWNLOAD")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(IndustrialButtonStyle())
                    .disabled(urlInput.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Download")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // UI Helpers
    private func modeButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.nothingMeta)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isActive ? DesignSystem.Colors.nothingRed : Color.secondary.opacity(0.1))
                .foregroundColor(isActive ? .white : .primary)
                .cornerRadius(12)
        }
    }
    
    private func pickerSection(title: String, items: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DotMatrixText(text: title)
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button(action: { selection.wrappedValue = item }) {
                        Text(item.uppercased())
                            .font(.nothingMeta)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selection.wrappedValue == item ? Color.primary : Color.secondary.opacity(0.1))
                            .foregroundColor(selection.wrappedValue == item ? Color(uiColor: .systemBackground) : .primary)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func startDownload() {
        guard !urlInput.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        DownloadManager.shared.addDownload(
            url: urlInput,
            quality: selectedResolution,
            audioOnly: isAudioOnly,
            format: selectedFormat,
            bitrate: selectedBitrate
        )
        
        urlInput = ""
    }
}

#Preview {
    DownloadView()
}
