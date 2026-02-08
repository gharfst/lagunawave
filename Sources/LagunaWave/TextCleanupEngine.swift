import Foundation
import MLXLLM
import MLXLMCommon

actor TextCleanupEngine {
    static let shared = TextCleanupEngine()

    enum CleanupModel: String, Sendable {
        case standard = "mlx-community/Qwen3-4B-4bit"
        case lightweight = "mlx-community/Qwen3-1.7B-4bit"
    }

    private static let systemPrompt = """
        You are a dictation post-processor. You receive raw speech-to-text output and return only the cleaned version. Rules:
        - Fix punctuation and capitalization
        - Remove filler words (um, uh, like, you know, I mean, so, basically, actually)
        - Fix common homophones (there/their/they're, your/you're, its/it's, to/too/two, then/than)
        - Never add, remove, or rephrase content beyond these corrections
        - Do not add greetings, commentary, or explanations
        - Return ONLY the corrected text, nothing else
        """

    private var modelContainer: ModelContainer?
    private var loadedModel: CleanupModel?
    private var loadingTask: Task<Void, Error>?

    func isReady() -> Bool { modelContainer != nil }

    private func selectedModel() -> CleanupModel {
        let modelString = UserDefaults.standard.string(forKey: "llmCleanupModel") ?? "standard"
        return modelString == "lightweight" ? .lightweight : .standard
    }

    func prepare(progressHandler: (@Sendable (Progress) -> Void)? = nil) async throws {
        let model = selectedModel()
        if modelContainer != nil, loadedModel == model {
            return
        }
        if modelContainer != nil, loadedModel != model {
            modelContainer = nil
            loadedModel = nil
            loadingTask = nil
        }
        if let task = loadingTask {
            try await task.value
            return
        }

        let handler = progressHandler
        let task = Task {
            let start = Date()
            Log.shared.write("TextCleanupEngine: loading model \(model.rawValue)")
            let container: ModelContainer
            if let handler {
                container = try await loadModelContainer(id: model.rawValue, progressHandler: handler)
            } else {
                container = try await loadModelContainer(id: model.rawValue)
            }
            modelContainer = container
            loadedModel = model
            let elapsed = Date().timeIntervalSince(start)
            Log.shared.write("TextCleanupEngine: model ready (\(String(format: "%.2f", elapsed))s)")
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

    func reloadModel() async throws {
        modelContainer = nil
        loadedModel = nil
        loadingTask = nil
        try await prepare()
    }

    func cleanUp(text: String) async throws -> String {
        try await prepare()
        guard let container = modelContainer else { return text }

        // enable_thinking=false tells the Qwen3 chat template to prefill an
        // empty <think> block, preventing the model from generating reasoning
        // tokens. Temperature 0.7 is Qwen3's recommended value for non-thinking mode.
        let session = ChatSession(
            container,
            instructions: Self.systemPrompt,
            generateParameters: GenerateParameters(maxTokens: 1024, temperature: 0.7, topP: 0.8),
            additionalContext: ["enable_thinking": false]
        )
        let result = try await session.respond(to: text)
        await session.clear()

        Log.shared.write("TextCleanupEngine: raw response=\(String(result.prefix(300)))")
        // Safety net: strip any residual think tags
        let cleaned = Self.stripThinkTags(result)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        Log.shared.write("TextCleanupEngine: cleaned=\(String(cleaned.prefix(300)))")
        return cleaned.isEmpty ? text : cleaned
    }

    private static func stripThinkTags(_ text: String) -> String {
        var result = text
        while let start = result.range(of: "<think>") {
            if let end = result.range(of: "</think>", range: start.upperBound..<result.endIndex) {
                result.removeSubrange(start.lowerBound..<end.upperBound)
            } else {
                result.removeSubrange(start.lowerBound..<result.endIndex)
            }
        }
        return result
    }

}
