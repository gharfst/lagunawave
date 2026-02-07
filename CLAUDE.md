# LagunaWave

Local, on-device dictation app for macOS. Records speech via a global hotkey, transcribes it offline using the Parakeet TDT v3 model (via FluidAudio), and simulates keystrokes into the focused app.

## Tech Stack

- Swift 6.0 / Swift Package Manager
- macOS 14+ (Sonoma)
- FluidAudio (ASR/CoreML), Carbon (global hotkeys), CGEvent (keystroke simulation)
- Menu bar accessory app (no dock icon)

## Build & Run

```bash
./scripts/build.sh    # Build release .app bundle
./scripts/run.sh      # Build + reset permissions + launch (for development)
```

## Development Notes

- **Accessibility & Microphone permissions**: Ad-hoc (dev) builds get a new code signature each time, which invalidates macOS privacy permissions. `run.sh` handles this by calling `tccutil reset` before launch. Production builds signed with Developer ID don't have this issue.
- **File provider (iCloud/Dropbox)**: The project may live on a synced drive. The build and notarize scripts stage to /tmp before code signing to avoid extended attribute contamination that breaks codesign.
- **Notarization**: Use `scripts/notarize.sh` or `scripts/release.sh`. Requires `CODESIGN_IDENTITY` and `NOTARYTOOL_PROFILE` env vars. First-time submissions to a new Apple developer account may be held for extended review (hours to days).

## Architecture

All source is in `Sources/LagunaWave/`. Key files:

- `AppDelegate.swift` — Main orchestrator and state machine (listen → transcribe → type)
- `AudioCapture.swift` — AVAudioEngine mic capture, resamples to 16kHz mono
- `TranscriptionEngine.swift` — Actor wrapping FluidAudio ASR, lazy model download
- `TextTyper.swift` — Simulates keystrokes via CGEvent (Unicode, virtual keycodes, or paste)
- `HotKeyManager.swift` — Global hotkey registration via Carbon
- `OverlayPanel.swift` — Non-activating floating HUD with branding, status, and hotkey hints
- `SettingsViewController.swift` — Settings UI (mic, hotkeys, typing method/speed, VDI keywords, feedback)
- `Preferences.swift` — UserDefaults wrapper (includes VDI app detection)

## Bundle ID

`com.nodogbite.lagunawave`
