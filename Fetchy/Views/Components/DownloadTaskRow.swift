import SwiftUI

struct DownloadTaskRow: View {
    @ObservedObject var task: DownloadTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.url)
                    .lineLimit(1)
                    .font(.caption)
                Spacer()
                Text(task.status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            ProgressView(value: task.progress)
                .tint(DesignSystem.Colors.nothingRed)
            
            if task.status == "COMPLETED" {
                Button(action: {
                    // Show preview
                }) {
                    Text("Show")
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DownloadTaskRow(task: DownloadTask(url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ", quality: "1080p", audioOnly: false, format: "mp4", bitrate: "192"))
}
