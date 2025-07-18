import Foundation

actor LogManager {
    static let shared = LogManager()
    
    private let appGroupIdentifier = "group.syferlab.wBlock"
    private let logFileName = "wblock_logs.txt"
    private let maxLogSize = 1024 * 1024 // 1MB
    
    private var logFileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { return nil }
        
        return containerURL.appendingPathComponent(logFileName)
    }
    
    private init() {}
    
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] \(message)\n"
        
        guard let logFileURL = logFileURL else { return }
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // Check file size and rotate if needed
                let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
                if let fileSize = attributes[.size] as? Int, fileSize > maxLogSize {
                    try rotateLog()
                }
                
                // Append to existing file
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                if let data = logEntry.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            } else {
                // Create new file
                try logEntry.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        } catch {
            print("Failed to write log: \(error)")
        }
    }
    
    func getLogs() -> String {
        guard let logFileURL = logFileURL,
              FileManager.default.fileExists(atPath: logFileURL.path) else {
            return "No logs available"
        }
        
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "Failed to read logs: \(error)"
        }
    }
    
    func clearLogs() {
        guard let logFileURL = logFileURL else { return }
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                try FileManager.default.removeItem(at: logFileURL)
            }
        } catch {
            print("Failed to clear logs: \(error)")
        }
    }
    
    private func rotateLog() throws {
        guard let logFileURL = logFileURL else { return }
        
        let backupURL = logFileURL.appendingPathExtension("old")
        
        // Remove old backup if exists
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        
        // Move current log to backup
        try FileManager.default.moveItem(at: logFileURL, to: backupURL)
    }
}
