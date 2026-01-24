import SwiftUI

struct DownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    
    var body: some View {
        VStack {
            if !downloadManager.tasks.isEmpty {
                List {
                    ForEach(downloadManager.tasks) { task in
                        DownloadTaskRow(task: task)
                    }
                }
            } else {
                Text("No active downloads")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Active Downloads")
    }
}

#Preview {
    DownloadsView()
}
