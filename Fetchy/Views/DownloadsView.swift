import SwiftUI
import QuickLook

struct DownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var previewURL: URL?
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    if downloadManager.tasks.isEmpty {
                        Section {
                            VStack(spacing: 20) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.quaternary)
                                DotMatrixText(text: "NO ACTIVE SEQUENCES")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        Section(header: DotMatrixText(text: "ACTIVE DOWNLOADS")) {
                            ForEach(downloadManager.tasks) { task in
                                DownloadTaskRow(task: task)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenQuickLook"))) { notification in
            if let url = notification.object as? URL {
                self.previewURL = url
            }
        }
        .sheet(item: Binding(
            get: { previewURL.map { IdentifiableURL(url: $0) } },
            set: { previewURL = $0?.url }
        )) { idURL in
            QuickLookView(url: idURL.url)
        }
    }
}

#Preview {
    DownloadsView()
}
