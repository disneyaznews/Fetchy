import SwiftUI

struct HistoryView: View {
    @State private var entries: [VideoEntry] = []
    @State private var offset: Int = 0
    private let limit: Int = 20
    
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var showingDeletePicker = false
    @State private var deleteBeforeDate = Date()
    @State private var titleTapCount = 0
    @State private var lastTapTime = Date()
    
    var body: some View {
            List {
                if entries.isEmpty {
                    Section {
                        VStack(spacing: 20) {
                            Image(systemName: "tray.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.quaternary)
                            DotMatrixText(text: "NO RECORDS FOUND", usesUppercase: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section(header: DotMatrixText(text: "RECENT SEQUENCES")) {
                        ForEach(entries) { entry in
                            let task = downloadManager.tasks.first(where: { $0.url == entry.url && $0.status != "COMPLETED" })
                            HistoryRow(entry: entry, task: task)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        
                        if entries.count >= limit && entries.count % limit == 0 {
                            Button(action: loadMore) {
                                Text("LOAD MORE")
                                    .font(.nothingMeta)
                                    .foregroundColor(DesignSystem.Colors.nothingRed)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingDeletePicker = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(DesignSystem.Colors.nothingRed)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("History")
                    .font(.system(size: 17, weight: .semibold))
                    .onTapGesture {
                        handleTitleTap()
                    }
            }
        }
        .overlay {
            if showingDeletePicker {
                bulkDeleteOverlay
            }
        }
        .onAppear {
            if entries.isEmpty {
                loadEntries()
            }
        }
    }
    
    private var bulkDeleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .onTapGesture { showingDeletePicker = false }
            
            VStack(spacing: 20) {
                DotMatrixText(text: "CLEAR RECORDS")
                
                DatePicker("Before Date", selection: $deleteBeforeDate, displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                HStack(spacing: 20) {
                    Button("CANCEL") { showingDeletePicker = false }
                        .font(.system(size: 15, weight: .medium))
                    
                    Button("DELETE") {
                        bulkDelete()
                        showingDeletePicker = false
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.nothingRed)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(24)
            .padding(40)
        }
    }
    
    private func handleTitleTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) < 0.5 {
            titleTapCount += 1
        } else {
            titleTapCount = 1
        }
        lastTapTime = now
        
        if titleTapCount >= 3 {
            insertMockData()
            titleTapCount = 0
        }
    }
    
    private func insertMockData() {
        let services = ["YouTube", "TikTok", "X", "Instagram", "Vimeo"]
        let statuses: [VideoEntry.DownloadStatus] = [.completed, .failed, .downloading, .pending]
        
        for i in 1...25 {
            let entry = VideoEntry(
                title: "Mock Video \(i)",
                url: "https://example.com/video/\(i)",
                service: services.randomElement()!,
                status: statuses.randomElement()!,
                localPath: "/tmp/mock\(i).mp4"
            )
            DatabaseManager.shared.insert(entry: entry, rawLog: "Mock log data for video \(i)")
        }
        
        // Reload
        loadEntries()
    }
    
    private func loadEntries() {
        let fetched = DatabaseManager.shared.fetchEntries(limit: limit, offset: 0)
        entries = fetched
        offset = limit
    }
    
    private func loadMore() {
        let more = DatabaseManager.shared.fetchEntries(limit: limit, offset: offset)
        if !more.isEmpty {
            entries.append(contentsOf: more)
            offset += limit
        }
    }
    
    private func deleteEntry(_ entry: VideoEntry) {
        DatabaseManager.shared.deleteEntry(id: entry.id)
        entries.removeAll { $0.id == entry.id }
    }
    
    private func bulkDelete() {
        DatabaseManager.shared.deleteEntries(before: deleteBeforeDate)
        loadEntries()
    }
}

struct HistoryRow: View {
    let entry: VideoEntry
    @ObservedObject var task: DownloadTask?

    var body: some View {
        NavigationLink(destination: DetailedLogView(targetEntryID: entry.id)) {
            HStack(spacing: 16) {
                ServiceIcon(entry.service, size: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.nothingBody)
                        .lineLimit(1)
                    
                    Text(entry.url)
                        .font(.nothingMeta)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusIndicator(status: entry.status, task: task)
                    Text(formatDate(entry.date))
                        .font(.nothingMeta)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}


struct StatusIndicator: View {
    let status: VideoEntry.DownloadStatus
    @ObservedObject var task: DownloadTask?
    
    var body: some View {
        if let task = task {
            ProgressView(value: task.progress)
                .scaleEffect(0.8)
        } else {
            switch status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.nothingRed)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.secondary)
            case .downloading:
                ProgressView()
                    .scaleEffect(0.8)
            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HistoryView()
}
