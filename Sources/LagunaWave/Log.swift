import Foundation

final class Log: @unchecked Sendable {
    static let shared = Log()

    private let queue = DispatchQueue(label: "lagunawave.log")
    private let url: URL
    private let formatter: ISO8601DateFormatter

    private init() {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let dir = library.appendingPathComponent("Logs/LagunaWave", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        url = dir.appendingPathComponent("lagunawave.log")
        formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    var logURL: URL {
        url
    }

    func write(_ message: String) {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: self.url.path),
               let handle = try? FileHandle(forWritingTo: self.url) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: self.url, options: .atomic)
            }
        }
        print(line, terminator: "")
    }
}
