import Foundation
import Combine

enum YTDLPError: LocalizedError {
    case apiError(String)
    case networkError(Error)
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .apiError(let msg): return msg
        case .networkError(let error): return error.localizedDescription
        case .timeout: return "Request timed out"
        case .unknown: return "An unknown error occurred"
        }
    }
}

class YTDLPManager {
    private var pollingTask: Task<Void, Error>?
    private let apiClient = APIClient()
    
    public init() {}
    
    /// Download video via Railway API
    func download(url: String,
                  quality: String = "1080p",
                  audioOnly: Bool = false,
                  format: String = "mp4",
                  bitrate: String = "192",
                  embedMetadata: Bool = true,
                  embedThumbnail: Bool = true,
                  removeSponsors: Bool = false,
                  embedSubtitles: Bool = false,
                  embedChapters: Bool = false,
                  outputTemplate: String? = nil, // Custom output path support
                  statusHandler: @escaping (Double, String, String?, String?) -> Void,
                  completion: @escaping (Result<URL, Error>, String?) -> Void) {
        
        pollingTask = Task {
            do {
                // Start download job
                let jobId = try await apiClient.startDownload(url: url, quality: quality, audioOnly: audioOnly, format: format, bitrate: bitrate, embedMetadata: embedMetadata, embedThumbnail: embedThumbnail, removeSponsors: removeSponsors, embedSubtitles: embedSubtitles, embedChapters: embedChapters)
                print("[API] Job started: \(jobId)")
                
                // Poll for status
                try await pollStatus(jobId: jobId, outputTemplate: outputTemplate, statusHandler: statusHandler, completion: completion)
                
            } catch {
                print("[API] Error starting download: \(error)")
                completion(.failure(error), nil)
            }
        }
    }
    
    /// Poll job status until completion
    private func pollStatus(jobId: String,
                           outputTemplate: String?,
                           statusHandler: @escaping (Double, String, String?, String?) -> Void,
                           completion: @escaping (Result<URL, Error>, String?) -> Void) async throws {
        
        print("[YTDLP] Starting poll for \(jobId)")
        var attempts = 0
        let maxAttempts = 600 // 5 minutes with 0.5s intervals
        
        while attempts < maxAttempts {
            do {
                let status = try await apiClient.getStatus(jobId: jobId)
                
                // Update progress
                statusHandler(status.progress, status.message, status.extractor, status.title)
                
                switch status.status {
                case "completed":
                    // Notify UI that we are now transferring the file
                    statusHandler(1.0, "DOWNLOADING FILE...", status.extractor, status.title)
                    
                    // Determine destination
                    let destinationURL: URL
                    if let template = outputTemplate {
                        destinationURL = URL(fileURLWithPath: template)
                    } else {
                        // Fallback logic (legacy)
                        let appGroupIdentifier = "group.com.nisesimadao.Fetchy"
                        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
                            completion(.failure(YTDLPError.apiError("Could not access App Group")), nil)
                            return
                        }
                        let downloadsDir = containerURL.appendingPathComponent("downloads", isDirectory: true)
                        try? FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
                        let fileName = status.filename ?? status.title?.appending(".mp4") ?? "video.mp4"
                        destinationURL = downloadsDir.appendingPathComponent(fileName)
                    }
                    
                    // Remove existing file at destination if present to ensure clean write
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try? FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    try await apiClient.downloadFile(jobId: jobId, to: destinationURL) { progress in
                        statusHandler(progress, "DOWNLOADING FILE...", status.extractor, status.title)
                    }
                    let log = try? await apiClient.getLog(jobId: jobId)
                    completion(.success(destinationURL), log)
                    return
                    
                case "failed":
                    let log = try? await apiClient.getLog(jobId: jobId)
                    completion(.failure(YTDLPError.apiError(status.message)), log)
                    return
                    
                default:
                    // Continue polling
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
                    attempts += 1
                }
                
            } catch {
                if error is CancellationError {
                    print("[YTDLP] Task cancelled.")
                    completion(.failure(error), nil)
                    return
                }
                print("[API] Polling error: \(error)")
                let log = try? await apiClient.getLog(jobId: jobId)
                completion(.failure(error), log)
                return
            }
        }
        
        let log = try? await apiClient.getLog(jobId: jobId)
        completion(.failure(YTDLPError.timeout), log)
    }
    
    func cancel() {
        pollingTask?.cancel()
    }
}
