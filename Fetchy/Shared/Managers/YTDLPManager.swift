import Foundation

enum YTDLPError: Error {
    case binaryNotFound
    case processFailed(Int32)
    case cancelled
    case unknown
    case osNotSupported
}

class YTDLPManager: ObservableObject {
    static let shared = YTDLPManager()
    
    private var currentProcess: Process?
    private var outputPipe: Pipe?
    
    func download(url: String, 
                  quality: String = "1080p", // Placeholder for format selection logic
                  progressHandler: @escaping (Double) -> Void, 
                  completion: @escaping (Result<URL, Error>) -> Void) {
        
        guard let binaryPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil) else {
            completion(.failure(YTDLPError.binaryNotFound))
            return
        }
        
        // Setup Temporary Directory
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let outputPathTemplate = tempDir.appendingPathComponent("%(title)s.%(ext)s").path
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        
        // Basic arguments: Print JSON progress, Output template
        process.arguments = [
            "--newline",
            "--progress",
            "-o", outputPathTemplate,
            url
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe // Capture error output too/or separate
        self.outputPipe = pipe
        self.currentProcess = process
        
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty { return }
            if let str = String(data: data, encoding: .utf8) {
                // Parse Progress
                // Example: [download]  23.5% of 10.00MiB at 100.00KiB/s ETA 00:30
                self.parseProgress(from: str, handler: progressHandler)
            }
        }
        
        process.terminationHandler = { proc in
            outHandle.readabilityHandler = nil
            
            if proc.terminationStatus == 0 {
                // Find the downloaded file
                do {
                    let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
                    if let videoFile = files.first {
                        completion(.success(videoFile))
                    } else {
                        completion(.failure(YTDLPError.unknown))
                    }
                } catch {
                    completion(.failure(error))
                }
            } else {
                completion(.failure(YTDLPError.processFailed(proc.terminationStatus)))
            }
            self.currentProcess = nil
        }
        
        do {
            try process.run()
        } catch {
            completion(.failure(error))
        }
    }
    
    func cancel() {
        currentProcess?.terminate()
        currentProcess = nil
    }
    
    private func parseProgress(from output: String, handler: @escaping (Double) -> Void) {
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if line.contains("[download]") && line.contains("%") {
                // Rudimentary parsing
                // [download]  12.3% ...
                let components = line.components(separatedBy: CharacterSet.whitespaces)
                for comp in components {
                    if comp.contains("%") {
                        let numStr = comp.replacingOccurrences(of: "%", with: "")
                        if let val = Double(numStr) {
                            DispatchQueue.main.async {
                                handler(val / 100.0)
                            }
                        }
                    }
                }
            }
        }
    }
}
