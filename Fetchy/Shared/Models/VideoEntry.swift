import Foundation

struct VideoEntry: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let service: String
    let date: Date
    var status: DownloadStatus
    var rawLog: String? // Kept as requested
    var localPath: String?
    
    enum DownloadStatus: String, Codable {
        case pending
        case downloading
        case completed
        case failed
        case cancelled
        case aborted // System/OS interruption
    }
    
    init(id: UUID = UUID(), title: String, url: String, service: String = "Unknown", date: Date = Date(), status: DownloadStatus = .pending, rawLog: String? = nil, localPath: String? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.service = service
        self.date = date
        self.status = status
        self.rawLog = rawLog
        self.localPath = localPath
    }
}
