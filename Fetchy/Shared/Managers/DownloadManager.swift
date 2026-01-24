import Foundation
import Combine

class DownloadTask: ObservableObject, Identifiable {
    let id = UUID()
    @Published var url: String
    @Published var progress: Double = 0.0
    @Published var status: String = "QUEUED"
    @Published var fileURL: URL?
    
    // YTDLP options
    let quality: String
    let audioOnly: Bool
    let format: String
    let bitrate: String

    private var ytdlpManager = YTDLPManager()
    private var cancellables = Set<AnyCancellable>()
    private let progressSubject = PassthroughSubject<Double, Never>()

    init(url: String, quality: String, audioOnly: Bool, format: String, bitrate: String) {
        self.url = url
        self.quality = quality
        self.audioOnly = audioOnly
        self.format = format
        self.bitrate = bitrate
        
        progressSubject
            .throttle(for: .seconds(0.1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &cancellables)
    }

    func start() {
        self.status = "INITIALIZING..."
        ytdlpManager.download(
            url: self.url,
            quality: self.quality,
            audioOnly: self.audioOnly,
            format: self.format,
            bitrate: self.bitrate,
            statusHandler: { [weak self] progress, status in
                self?.progressSubject.send(progress)
                DispatchQueue.main.async {
                    self?.status = status.uppercased()
                }
            },
            completion: { [weak self] result, logs in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let fileURL):
                        self?.status = "COMPLETED"
                        self?.progress = 1.0
                        self?.fileURL = fileURL
                        let entry = VideoEntry(
                            title: fileURL.lastPathComponent,
                            url: self?.url ?? "",
                            service: "Direct",
                            status: .completed,
                            localPath: fileURL.path
                        )
                        DatabaseManager.shared.insert(entry: entry, rawLog: logs)

                    case .failure(let error):
                        self?.status = "ERROR: \(error.localizedDescription)"
                        let entry = VideoEntry(
                            title: "Failed: \(URL(string: self?.url ?? "")?.host ?? "Link")",
                            url: self?.url ?? "",
                            service: "Direct",
                            status: .failed,
                            localPath: nil
                        )
                        DatabaseManager.shared.insert(entry: entry, rawLog: logs ?? error.localizedDescription)
                    }
                }
            }
        )
    }

    func cancel() {
        ytdlpManager.cancel()
        self.status = "CANCELLED"
    }
}

class DownloadManager: ObservableObject {
    static let shared = DownloadManager()
    @Published var tasks: [DownloadTask] = []

    func addDownload(url: String, quality: String, audioOnly: Bool, format: String, bitrate: String) {
        let task = DownloadTask(url: url, quality: quality, audioOnly: audioOnly, format: format, bitrate: bitrate)
        tasks.append(task)
        task.start()
    }
}
