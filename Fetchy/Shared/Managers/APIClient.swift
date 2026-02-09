import Foundation
import Combine

/// API client for communicating with Railway backend
class APIClient {
    // IMPORTANT: Replace with your Railway public domain
    // 1. Go to Railway Dashboard → Settings → Networking
    // 2. Click "Generate Domain" under Public Networking
    // 3. Copy the generated URL (e.g., https://fetchy-api-production-xxxx.up.railway.app)
    // 4. Paste it here (without trailing slash)
    private let baseURL = "https://fetchy-api-production.up.railway.app"
    
    private let session: URLSession
    
    public init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
    }
    
    /// Start a download job
    func startDownload(url: String, quality: String = "1080p", audioOnly: Bool = false, format: String = "mp4", bitrate: String = "192", embedMetadata: Bool = true, embedThumbnail: Bool = true, removeSponsors: Bool = false, embedSubtitles: Bool = false, embedChapters: Bool = false) async throws -> String {
        let endpoint = URL(string: "\(baseURL)/api/download")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "url": url, 
            "quality": quality,
            "audioOnly": audioOnly,
            "format": format,
            "bitrate": bitrate,
            "embedMetadata": embedMetadata,
            "embedThumbnail": embedThumbnail,
            "removeSponsors": removeSponsors,
            "embedSubtitles": embedSubtitles,
            "embedChapters": embedChapters
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let result = try JSONDecoder().decode(DownloadResponse.self, from: data)
        return result.jobId
    }
    
    /// Get job status
    func getStatus(jobId: String) async throws -> JobStatus {
        let endpoint = URL(string: "\(baseURL)/api/status/\(jobId)")!
        let (data, _) = try await session.data(from: endpoint)
        return try JSONDecoder().decode(JobStatus.self, from: data)
    }
    
    /// Download completed file
    /// Download completed file with progress tracking
    func downloadFile(jobId: String, to destination: URL, progressHandler: ((Double) -> Void)? = nil) async throws {
        let endpoint = URL(string: "\(baseURL)/api/download/\(jobId)")!
        
        // Use a continuation to wrap the delegate-based download task
        try await withCheckedThrowingContinuation { continuation in
            let delegate = DownloadDelegate(progressHandler: progressHandler, destination: destination, continuation: continuation)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
            let task = session.downloadTask(with: endpoint)
            task.resume()
            // Session is retained by the task/delegate cycle until completion
        }
    }
    
    // Internal Delegate to handle progress and completion
    private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
        let progressHandler: ((Double) -> Void)?
        let destination: URL
        let continuation: CheckedContinuation<Void, Error>
        
        init(progressHandler: ((Double) -> Void)?, destination: URL, continuation: CheckedContinuation<Void, Error>) {
            self.progressHandler = progressHandler
            self.destination = destination
            self.continuation = continuation
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            progressHandler?(progress)
        }
        
        func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }
        
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let error = error {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Get raw log
    func getLog(jobId: String) async throws -> String {
        let endpoint = URL(string: "\(baseURL)/api/log/\(jobId)")!
        let (data, _) = try await session.data(from: endpoint)
        let result = try JSONDecoder().decode(LogResponse.self, from: data)
        return result.log
    }
}

// MARK: - Models

struct DownloadResponse: Codable {
    let jobId: String
}

struct JobStatus: Codable {
    let status: String
    let progress: Double
    let message: String
    let downloadUrl: String?
    let title: String?
    let filename: String?
    let extractor: String?
}

struct LogResponse: Codable {
    let log: String
}

enum APIError: LocalizedError {
    case invalidResponse
    case downloadFailed
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .downloadFailed:
            return "Download failed"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}
