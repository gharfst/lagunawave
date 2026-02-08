import Foundation
import os

// MARK: - os.Logger categories (Console.app, Xcode, `log` CLI)

extension Logger {
    private static let sub = "com.nodogbite.lagunawave"

    static let general       = Logger(subsystem: sub, category: "general")
    static let audio         = Logger(subsystem: sub, category: "audio")
    static let transcription = Logger(subsystem: sub, category: "transcription")
    static let cleanup       = Logger(subsystem: sub, category: "cleanup")
    static let typing        = Logger(subsystem: sub, category: "typing")
    static let hotkey        = Logger(subsystem: sub, category: "hotkey")
}

// MARK: - Dual logger (os.Logger + rotating file)

enum Log {
    static func general(_ msg: String) {
        Logger.general.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
    static func audio(_ msg: String) {
        Logger.audio.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
    static func transcription(_ msg: String) {
        Logger.transcription.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
    static func cleanup(_ msg: String) {
        Logger.cleanup.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
    static func typing(_ msg: String) {
        Logger.typing.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
    static func hotkey(_ msg: String) {
        Logger.hotkey.notice("\(msg, privacy: .public)")
        FileLog.shared.write(msg)
    }
}

// MARK: - Rotating file logger (for user-facing diagnostics)

// @unchecked Sendable: all mutable state is accessed exclusively from `queue`.
// Cannot use Mutex (requires macOS 15); DispatchQueue is the macOS 14 alternative.
final class FileLog: @unchecked Sendable {
    static let shared = FileLog()

    private let queue = DispatchQueue(label: "lagunawave.filelog")
    private let directory: URL
    private let currentFile: URL
    private let maxSize: UInt64 = 2_000_000 // 2 MB
    private let maxFiles = 3
    private let formatter: ISO8601DateFormatter

    var currentFileURL: URL { currentFile }
    var logDirectory: URL { directory }

    private init() {
        let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        directory = library.appendingPathComponent("Logs/LagunaWave", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        currentFile = directory.appendingPathComponent("lagunawave.log")
        formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    func write(_ message: String) {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        queue.async { [self] in
            guard let data = line.data(using: .utf8) else { return }
            rotateIfNeeded(incoming: data.count)
            if FileManager.default.fileExists(atPath: currentFile.path),
               let handle = try? FileHandle(forWritingTo: currentFile) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: currentFile, options: .atomic)
            }
        }
    }

    private func rotateIfNeeded(incoming: Int) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: currentFile.path),
              let size = attrs[.size] as? UInt64,
              size + UInt64(incoming) > maxSize else { return }

        let oldest = directory.appendingPathComponent("lagunawave.\(maxFiles).log")
        try? FileManager.default.removeItem(at: oldest)

        for i in stride(from: maxFiles - 1, through: 1, by: -1) {
            let src = directory.appendingPathComponent("lagunawave.\(i).log")
            let dst = directory.appendingPathComponent("lagunawave.\(i + 1).log")
            try? FileManager.default.moveItem(at: src, to: dst)
        }

        let first = directory.appendingPathComponent("lagunawave.1.log")
        try? FileManager.default.moveItem(at: currentFile, to: first)
    }
}
