import Foundation

extension String {
    func appendLine(to url: URL) throws {
        try (self).append(to: url, encoding: .utf8)
    }
    
    func append(to url: URL, encoding: String.Encoding) throws {
        let data = self.data(using: encoding)!
        if let fileHandle = FileHandle(forWritingAtPath: url.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        } else {
            try data.write(to: url, options: .atomic)
        }
    }
}

func fileLog(_ msg: String) {
    #if DEBUG
    let logFile = FileManager.default.temporaryDirectory.appendingPathComponent("VirtualScreen_Log.txt")
    let entry = "\(Date()): \(msg)\n"
    try? entry.appendLine(to: logFile)
    #endif
}
