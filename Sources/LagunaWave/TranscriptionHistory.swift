import Foundation

struct TranscriptionRecord: Codable {
    let id: UUID
    let text: String
    let date: Date

    init(text: String, date: Date = Date()) {
        self.id = UUID()
        self.text = text
        self.date = date
    }
}

@MainActor
final class TranscriptionHistory {
    static let shared = TranscriptionHistory()

    private let defaults = UserDefaults.standard
    private let key = "transcriptionHistory"
    private let maxItems = 50

    private(set) var records: [TranscriptionRecord] = []

    private init() {
        load()
    }

    func append(_ text: String) {
        let record = TranscriptionRecord(text: text)
        records.insert(record, at: 0)
        if records.count > maxItems {
            records = Array(records.prefix(maxItems))
        }
        save()
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }

    func delete(at index: Int) {
        guard records.indices.contains(index) else { return }
        records.remove(at: index)
        save()
        NotificationCenter.default.post(name: .historyDidChange, object: nil)
    }

    private func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([TranscriptionRecord].self, from: data) else {
            return
        }
        records = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: key)
        }
    }
}
