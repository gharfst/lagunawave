import Foundation
import FluidAudio

actor TranscriptionEngine {
    private var manager: AsrManager?
    private var loadingTask: Task<Void, Error>?

    func isReady() -> Bool {
        return manager != nil
    }

    func prepare() async throws {
        if manager != nil {
            return
        }
        if let task = loadingTask {
            try await task.value
            return
        }

        let task = Task {
            let start = Date()
            Log.shared.write("TranscriptionEngine: loading model")
            let models = try await AsrModels.downloadAndLoad(version: .v3)
            let mgr = AsrManager(config: .default)
            try await mgr.initialize(models: models)
            manager = mgr
            let elapsed = Date().timeIntervalSince(start)
            Log.shared.write("TranscriptionEngine: model ready (\(String(format: "%.2f", elapsed))s)")
        }
        loadingTask = task
        do {
            try await task.value
        } catch {
            loadingTask = nil
            throw error
        }
        loadingTask = nil
    }

    func transcribe(samples: [Float]) async throws -> String {
        try await prepare()
        guard let manager = manager else { return "" }
        Log.shared.write("TranscriptionEngine: transcribing \(samples.count) samples")
        let result = try await manager.transcribe(samples, source: .microphone)
        return result.text
    }
}
