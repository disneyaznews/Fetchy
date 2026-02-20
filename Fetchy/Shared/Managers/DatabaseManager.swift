import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    // Load App Group identifier from Info.plist for flexibility across build variants (e.g. AltStore, future renaming)
    var appGroupIdentifier: String {
        if let id = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String {
            return id
        }
        // Fallback for legacy or dev/test use
        return "group.com.nisesimadao.Fetchy"
    }
    
    private var dbPath: String {
        let fileManager = FileManager.default
        guard let containerURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            // Fallback to documents directoy if App Group is unavailable
            let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0].appendingPathComponent("fetchy.sqlite").path
        }
        
        let targetPath = containerURL.appendingPathComponent("fetchy.sqlite").path
        
        // Migrate old DB if it exists in locally
        let oldPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let oldPath = oldPaths[0].appendingPathComponent("fetchy.sqlite").path
        if fileManager.fileExists(atPath: oldPath) && !fileManager.fileExists(atPath: targetPath) {
            try? fileManager.moveItem(atPath: oldPath, toPath: targetPath)
            print("Database migrated to App Group container.")
        }
        
        return targetPath
    }
    
    init() {
        openDatabase()
        enableWAL()
        createTable()
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func enableWAL() {
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
    }
    
    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS VideoEntries(
            id TEXT PRIMARY KEY,
            title TEXT,
            url TEXT,
            service TEXT,
            date REAL,
            status TEXT,
            localPath TEXT,
            rawLog TEXT
        );
        CREATE INDEX IF NOT EXISTS idx_date ON VideoEntries(date);
        CREATE INDEX IF NOT EXISTS idx_service ON VideoEntries(service);
        CREATE INDEX IF NOT EXISTS idx_status ON VideoEntries(status);
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("VideoEntries table created.")
            } else {
                print("VideoEntries table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func insert(entry: VideoEntry, rawLog: String? = nil) {
        let insertStatementString = "INSERT INTO VideoEntries (id, title, url, service, date, status, localPath, rawLog) VALUES (?, ?, ?, ?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            let idStr = entry.id.uuidString as NSString
            let titleStr = entry.title as NSString
            let urlStr = entry.url as NSString
            let serviceStr = entry.service as NSString
            let dateVal = entry.date.timeIntervalSince1970
            let statusStr = entry.status.rawValue as NSString
            let localPathStr = (entry.localPath ?? "") as NSString
            
            // Truncate logs if they are too large (> 10KB) to prevent DB bloating
            var rawLogStr = (rawLog ?? entry.rawLog ?? "") as NSString
            if rawLogStr.length > 10000 {
                let suffix = rawLogStr.substring(from: rawLogStr.length - 10000)
                rawLogStr = "[Log truncated for brevity...]\n\(suffix)" as NSString
            }
            
            sqlite3_bind_text(insertStatement, 1, idStr.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, titleStr.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, urlStr.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, serviceStr.utf8String, -1, nil)
            sqlite3_bind_double(insertStatement, 5, dateVal)
            sqlite3_bind_text(insertStatement, 6, statusStr.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 7, localPathStr.utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 8, rawLogStr.utf8String, -1, nil)
            
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted row.")
            } else {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func fetchEntries(limit: Int = 20, offset: Int = 0) -> [VideoEntry] {
        let queryStatementString = "SELECT * FROM VideoEntries ORDER BY date DESC LIMIT ? OFFSET ?;"
        var queryStatement: OpaquePointer?
        var entries: [VideoEntry] = []
        
        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(limit))
            sqlite3_bind_int(queryStatement, 2, Int32(offset))
            
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                // Safeguard against NULL explicitly to prevent crashes
                let idStr = String(cString: sqlite3_column_text(queryStatement, 0)!)
                let title = String(cString: sqlite3_column_text(queryStatement, 1)!)
                let url = String(cString: sqlite3_column_text(queryStatement, 2)!)
                let service = String(cString: sqlite3_column_text(queryStatement, 3)!)
                let dateVal = sqlite3_column_double(queryStatement, 4)
                let statusStr = String(cString: sqlite3_column_text(queryStatement, 5)!)
                
                // Safe unwrap for optional columns
                var localPath: String? = nil
                if let cStr = sqlite3_column_text(queryStatement, 6) {
                    localPath = String(cString: cStr)
                }
                
                var rawLog: String? = nil
                if let cStr = sqlite3_column_text(queryStatement, 7) {
                    rawLog = String(cString: cStr)
                }
                
                if let id = UUID(uuidString: idStr),
                   let status = VideoEntry.DownloadStatus(rawValue: statusStr) {
                    
                    let finalLocalPath = (localPath?.isEmpty ?? true) ? nil : localPath
                    
                    let entry = VideoEntry(
                        id: id,
                        title: title,
                        url: url,
                        service: service,
                        date: Date(timeIntervalSince1970: dateVal),
                        status: status,
                        rawLog: rawLog,
                        localPath: finalLocalPath
                    )
                    entries.append(entry)
                }
            }
        } else {
            print("SELECT statement could not be prepared")
        }
        sqlite3_finalize(queryStatement)
        return entries
    }
    
    func deleteEntry(id: UUID) {
        let deleteStatementString = "DELETE FROM VideoEntries WHERE id = ?;"
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            sqlite3_step(deleteStatement)
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func deleteEntries(before date: Date) {
        let deleteStatementString = "DELETE FROM VideoEntries WHERE date < ?;"
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_double(deleteStatement, 1, date.timeIntervalSince1970)
            sqlite3_step(deleteStatement)
        }
        sqlite3_finalize(deleteStatement)
    }
    
    func fetchRawLog(for id: UUID) -> String? {
        let queryString = "SELECT rawLog FROM VideoEntries WHERE id = ?;"
        var queryStatement: OpaquePointer?
        var log: String? = nil
        if sqlite3_prepare_v2(db, queryString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(queryStatement, 1, (id.uuidString as NSString).utf8String, -1, nil)
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                if let cStr = sqlite3_column_text(queryStatement, 0) {
                    log = String(cString: cStr)
                }
            }
        }
        sqlite3_finalize(queryStatement)
        return log
    }
    
    deinit {
        sqlite3_close(db)
    }
}
