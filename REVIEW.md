# Code & Documentation Review — LagunaWave

*Generated 2026-02-08*

---

## HIGH Priority

### 1. `branch: "main"` in Package.swift

`mlx-swift-lm` dependency is pinned to `branch: "main"`, not a version tag. Every `swift package resolve` or clean build could pull a different commit. A breaking upstream change could silently break your build.

**Recommendation:** Replace with a pinned `revision:` (specific commit hash) or a tagged version (`from: "X.Y.Z"`). If `mlx-swift-lm` doesn't publish stable tags, pin to the exact commit you've tested against. Always commit `Package.resolved` to source control.

**File:** `Package.swift`

---

### 2. Force casts on Accessibility API

`AXUIElementCopyAttributeValue` results are force-cast (`as! String`). A missing or unexpected attribute would crash the app.

**Recommendation:** Use conditional casts (`as? String`) with a fallback.

**File:** `Sources/LagunaWave/AppDelegate.swift` (focus capture/restore logic)

---

### 3. Unbounded log file growth

`Log.swift` appends to a single file forever with no rotation or size cap. On a machine that uses LagunaWave daily, this file will grow indefinitely.

**Recommendation:** Either switch to Apple's unified `os.Logger` (preferred — zero-overhead for disabled levels, automatic retention management, viewable in Console.app) or add a simple size cap / rotation to the existing file logger.

**File:** `Sources/LagunaWave/Log.swift`

---

### 4. `@unchecked Sendable` usage

`AudioCapture` and `Log` use `@unchecked Sendable` with manual `DispatchQueue` synchronization. This works but is fragile — the compiler can't verify thread safety, and future maintenance could introduce data races silently.

**Recommendation:** For macOS 15+, use `Mutex` from the `Synchronization` framework. For macOS 14 compatibility, `@unchecked Sendable` with `DispatchQueue` is acceptable but should be documented with comments explaining the synchronization strategy. Consider `@preconcurrency import` for third-party types (like `AsrManager`) instead of `@retroactive @unchecked Sendable`.

**Files:** `Sources/LagunaWave/AudioCapture.swift`, `Sources/LagunaWave/Log.swift`, `Sources/LagunaWave/SendableFixes.swift`

---

## MEDIUM Priority

### 5. Overlay border color doesn't update on appearance change

The overlay panel's border color is set once at init. Toggling between dark and light mode doesn't refresh it.

**Recommendation:** Override `viewDidChangeEffectiveAppearance()` or observe `NSApp.effectiveAppearance` to update the border color.

**File:** `Sources/LagunaWave/OverlayPanel.swift`

---

### 6. Menu bar uses text "LW" instead of a template image

Best practice for macOS menu bar apps is a monochrome `NSImage` with `isTemplate = true`. This automatically adapts to light/dark mode, active/inactive menu bar states, and accessibility settings.

**Recommendation:** Replace the text status item with a small template image (16x16 or 18x18 SF Symbol or custom icon).

**File:** `Sources/LagunaWave/AppDelegate.swift` (menu bar setup)

---

### 7. Overlay appears on main screen, not active screen

`NSScreen.main` is used to position the overlay, but this refers to the screen with the key window (or the screen with the menu bar if no window is key). On multi-monitor setups, this may not be the screen where the user is typing.

**Recommendation:** Use `NSScreen.screens.first(where:)` to find the screen containing the frontmost app's focused window, or fall back to `NSScreen.main`.

**File:** `Sources/LagunaWave/OverlayPanel.swift`

---

### 8. Preferences doesn't use `register(defaults:)`

Default values are handled via nil-coalescing (`?? value`) at every call site. This is fragile and duplicates defaults across the codebase.

**Recommendation:** Call `UserDefaults.standard.register(defaults:)` once at app launch with all default values. Consider a `@UserDefault` property wrapper for type-safe, centralized access.

**File:** `Sources/LagunaWave/Preferences.swift`

---

### 9. Duplicated `sign_metallibs` function

The `sign_metallibs()` function is copy-pasted identically in both `build.sh` and `notarize.sh`.

**Recommendation:** Extract to a shared helper script (e.g., `scripts/_common.sh`) and source it from both scripts.

**Files:** `scripts/build.sh`, `scripts/notarize.sh`

---

### 10. `--deep` codesigning flag

Apple discourages `--deep` for production signing. It applies the same signing options to every nested binary, but different binaries may need different entitlements.

**Recommendation:** Sign each component individually (inside-out): metallibs first, then the main executable, then the app bundle. Remove `--deep` from both signing and verification.

**Files:** `scripts/build.sh`, `scripts/notarize.sh`

---

## LOW Priority

### 11. Irrelevant `.gitignore` entries

The `.gitignore` contains Python (`__pycache__/`, `*.pyc`, `.venv/`), Node.js (`node_modules/`), and other entries that don't apply to a Swift/SPM project. Harmless but adds noise.

**Recommendation:** Remove irrelevant entries. Add Swift/Xcode-specific ones: `xcuserdata/`, `DerivedData/`, `.swiftpm/xcode/xcuserdata/`, `*.dSYM`.

**File:** `.gitignore`

---

### 12. No audio device change notifications

Unplugging the selected microphone mid-session isn't handled. The audio engine may fail silently or crash.

**Recommendation:** Listen for `AVAudioSession.routeChangeNotification` (or CoreAudio's `kAudioHardwarePropertyDevices` on macOS) and gracefully handle device removal — stop capture, notify the user, and fall back to the default device.

**File:** `Sources/LagunaWave/AudioCapture.swift`

---

### 13. History stored in UserDefaults

50 transcription history entries stored as JSON in UserDefaults works fine at this scale but isn't ideal for structured data. UserDefaults is backed by a plist that's read entirely into memory.

**Recommendation:** Acceptable for now. If history grows beyond 50 items or gains search/filtering features, consider migrating to a SQLite database or SwiftData.

**File:** `Sources/LagunaWave/TranscriptionHistory.swift`

---

### 14. Large AppDelegate (678 lines)

The `AppDelegate` serves as the main orchestrator, menu builder, state machine, and notification handler. It works but is dense.

**Recommendation:** Consider extracting the state machine (listen → transcribe → type) into a dedicated `DictationStateMachine` class, and the menu building into a `MenuManager`. Not urgent — this is a "when it starts hurting" refactor.

**File:** `Sources/LagunaWave/AppDelegate.swift`

---

### 15. Push-to-talk trailing buffer race condition

Rapid press/release cycles could queue multiple `finishListening()` calls via the 200ms `asyncAfter` delay, potentially causing double-transcription or state confusion.

**Recommendation:** Add a guard (e.g., a `pendingFinish` flag or `DispatchWorkItem` that gets cancelled on re-press) to ensure only one `finishListening` executes.

**File:** `Sources/LagunaWave/AppDelegate.swift` (`hotKeyReleased`)

---

### 16. No update mechanism

Users must manually check GitHub Releases for new versions.

**Recommendation:** Consider integrating [Sparkle](https://sparkle-project.org/) for automatic update checking. It's the de facto standard for non-App Store macOS apps.

---

### 17. No CONTRIBUTING.md

The project is open-source (MIT) and has setup/build scripts, but no contributor guidelines.

**Recommendation:** Add a brief `CONTRIBUTING.md` covering: how to build, how to run, code style expectations, and how to submit PRs.

---

## Things Done Well

- **Actor-based engines** — `TranscriptionEngine` and `TextCleanupEngine` use Swift actors correctly for thread-safe async work.
- **Clean settings UI** — `NSTabViewController` with `.toolbar` style follows macOS HIG.
- **Staged codesigning** — Building to `/tmp` before signing avoids extended attribute contamination from cloud drives (iCloud, Dropbox). This is an uncommon and excellent practice.
- **Graceful permission onboarding** — Walks users through Accessibility and Microphone permissions one at a time.
- **Good script organization** — Follows the "scripts to rule them all" pattern with clear, well-structured shell scripts.
- **Comprehensive README** — Covers build, run, signing, notarization, architecture, and model documentation.
- **Three typing methods** — Supporting Unicode injection, virtual keycodes, and clipboard paste covers the full spectrum of target apps (native, VDI, remote desktop).
