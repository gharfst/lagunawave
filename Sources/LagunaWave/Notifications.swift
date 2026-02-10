import Foundation

extension Notification.Name {
    static let inputDeviceChanged = Notification.Name("LagunaWave.InputDeviceChanged")
    static let pushHotKeyChanged = Notification.Name("LagunaWave.PushHotKeyChanged")
    static let toggleHotKeyChanged = Notification.Name("LagunaWave.ToggleHotKeyChanged")
    static let retypeTranscription = Notification.Name("LagunaWave.RetypeTranscription")
    static let historyDidChange = Notification.Name("LagunaWave.HistoryDidChange")
    static let modelChanged = Notification.Name("LagunaWave.ModelChanged")
    static let llmCleanupModelChanged = Notification.Name("LagunaWave.LLMCleanupModelChanged")
    static let hotKeyRecordingDidStart = Notification.Name("LagunaWave.HotKeyRecordingDidStart")
    static let hotKeyRecordingDidEnd = Notification.Name("LagunaWave.HotKeyRecordingDidEnd")
}
