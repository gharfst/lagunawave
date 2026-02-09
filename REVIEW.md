# Code Review: LagunaWave

## Bugs

### 1. OverlayPanel: dismiss/present race condition
**Severity: Medium** | `OverlayPanel.swift:211-218`

`dismiss()` schedules a non-cancellable `DispatchQueue.main.asyncAfter(deadline: .now() + 0.12)` that calls `panel.orderOut(nil)`. This block is fire-and-forget — it's not wrapped in a `DispatchWorkItem` and is not tracked by any instance variable.

If any `show*()` method is called within 0.12s after `dismiss()` runs, `present()` will fade the panel back in, but then the stale deferred block fires and yanks the panel off-screen via `orderOut(nil)`.

**Concrete trigger:** User gets "No speech detected" (which calls `hide(after: 0.8)`). At T+0.8s, the `hideWorkItem` fires `dismiss()`. If the user presses their hotkey within the next 0.12s, `showListening()` brings the panel back — but then the deferred block hides it. The user is now recording with no visual feedback.

**Fix:** Wrap the deferred block in a stored `DispatchWorkItem` and cancel it at the top of `present()`.

---

### 2. AudioCapture: no handling of audio device changes
**Severity: High** | `AudioCapture.swift`

There is zero observation of `AVAudioEngine.configurationChangeNotification` anywhere in the codebase. When the user plugs in headphones, connects AirPods, or changes the default input in System Settings while recording, `AVAudioEngine` can silently break — delivering silence or stopping entirely. The user gets no feedback and no automatic recovery.

The in-app microphone menu only stores the UID for the *next* recording session (`setInputDevice` doesn't restart the engine). It doesn't handle external device changes at all.

**Fix:** Observe `.AVAudioEngineConfigurationChange` on the engine instance. In the handler: stop the engine, remove the tap, reinstall the tap with the new format, and restart.

---

### 3. TranscriptionHistory: silent data loss on decode failure
**Severity: Low now, high risk for future** | `TranscriptionHistory.swift:48-54`

```swift
private func load() {
    guard let data = defaults.data(forKey: key),
          let decoded = try? JSONDecoder().decode([TranscriptionRecord].self, from: data) else {
        return
    }
    records = decoded
}
```

If decoding fails (e.g., a future version adds a non-optional field), `try?` swallows the error and `records` stays empty — all history is silently lost. No error is logged.

**Fix:** Log decode errors. Consider implementing `init(from:)` with defensive decoding for future-proofing.

---

## Design Concerns

### 4. TextTyper blocks the Swift cooperative thread pool
**Severity: Low-Medium** | `TextTyper.swift:207-209`, `AppDelegate.swift:363`

`typeText()` uses `usleep()` for inter-character delays. It's called from `Task {}` blocks in `finishListening()` and `completeRetypeFlow()`, which run on the cooperative thread pool. At "Natural" speed (35ms) with a 500-character transcription, this blocks a cooperative thread for ~21 seconds.

The app stays responsive because UI runs on the main thread, and modern Macs have enough cores that one blocked thread isn't critical. But it violates Swift concurrency's cooperative contract and could cause thread starvation on 4-core machines or if future features add concurrent tasks.

**Fix:** Either make the typing methods `async` using `Task.sleep` instead of `usleep`, or dispatch the typing work onto a dedicated `DispatchQueue`.

---

### 5. No mechanism to unload ML models from memory
**Severity: Low-Medium** | `TranscriptionEngine.swift`, `TextCleanupEngine.swift`

Both the ASR model (~600MB-1GB) and the cleanup LLM (~2.5GB for Qwen3-4B) stay loaded in memory for the entire app lifetime once loaded at startup. On an 8GB Mac, this leaves limited headroom for other apps. There's no idle unloading or memory pressure response.

---

### 6. `performFirstRunSetup` polls indefinitely for Accessibility
**Severity: Low** | `AppDelegate.swift:87-89`

```swift
while !AXIsProcessTrusted() {
    try? await Task.sleep(nanoseconds: 500_000_000)
}
```

If the user dismisses the accessibility dialog without granting permission, this loop runs forever. The app never finishes setup — models are never downloaded, and the overlay stays stuck on "Enable Accessibility...". The user can still use the menu bar, but the app is non-functional.

---

### 7. HotKeyManager: no `deinit` cleanup
**Severity: Very Low** | `HotKeyManager.swift`

The Carbon event handler and hotkey registrations are never cleaned up when `HotKeyManager` is deallocated. The `unregister()` method exists but has no `deinit` calling it. Harmless in practice since the manager lives for the app's lifetime and the OS cleans up on process exit, but technically a resource leak.

---

### 8. Keycode typing silently drops non-ASCII characters
**Severity: Low** | `TextTyper.swift:84-89`

The `simulateKeypresses` mode uses a hardcoded US QWERTY keycode map. Characters not in the map (accented characters, smart quotes, em dashes, non-Latin scripts) are silently skipped. The log records skipped counts, but the user gets incomplete output. This mode is intentionally a VDI fallback, but users may not understand why characters are missing.

---

## Summary

| # | Issue | Severity | Type |
|---|-------|----------|------|
| 1 | Overlay dismiss/present race | Medium | Bug |
| 2 | No audio device change handling | High | Bug |
| 3 | Silent history data loss on decode failure | Low* | Bug |
| 4 | usleep blocks cooperative thread pool | Low-Medium | Design |
| 5 | ML models never unloaded from memory | Low-Medium | Design |
| 6 | Indefinite accessibility polling | Low | Design |
| 7 | HotKeyManager missing deinit | Very Low | Design |
| 8 | Keycode mode drops non-ASCII chars | Low | Design |

\* Low severity today, but high risk if the `TranscriptionRecord` schema ever changes.
