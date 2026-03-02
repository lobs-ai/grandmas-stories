# Code Review — Grandma's Stories
**Date:** 2025-07-18  
**Reviewer:** Reviewer Agent  
**Scope:** Full quality pass — correctness, Swift best practices, crashes, memory leaks, TestFlight readiness

---

## Summary

The app is in decent shape for a first experiment. Architecture is clean, accessibility is thoughtful, and the service layer has reasonable test coverage. However, there are **3 critical bugs** that will cause incorrect behavior in production, plus several TestFlight blockers. The recording flow is largely untested at the UI/integration level.

---

## 🔴 Critical

### 1. `settingsStore` in RecordingView and FreestyleRecordingView is not `@StateObject` — family members may load stale/empty

**File:** `Views/Recording/RecordingView.swift` ~line 22, `FreestyleRecordingView.swift` ~line 20

```swift
private var settingsStore = SettingsStore()  // plain var — not observed, inconsistent with app state
```

A plain `var` on a SwiftUI view struct is recreated on every render. The app injects `SettingsStore` via `@EnvironmentObject` at the app level, but both recording views ignore it and create their own independent instance. If a user updates family members, the RecordingView may read an out-of-sync copy. The correct fix is `@EnvironmentObject private var settingsStore: SettingsStore` (already wired up at app root).

---

### 2. `checkMeters()` is dead code — `silenceDetected` never fires

**File:** `Services/AudioRecorder.swift` lines 64–68

```swift
private func checkMeters() {
    guard let recorder else { return }
    recorder.updateMeters()
    _ = recorder.averagePower(forChannel: 0)  // result discarded
}
```

The meter timer fires every 0.1s but discards the power reading. `silenceDetected` is never set to `true`. If anything reads this published property expecting silence detection to work, it's always wrong. Either implement it or remove the timer and dead property.

---

### 3. `MessageComposer` loads audio file on main thread — UI freeze on share

**File:** `Views/Components/MessageComposer.swift` ~line 23

```swift
if let data = try? Data(contentsOf: url) {  // synchronous, blocking, main thread
    vc.addAttachmentData(data, ...)
}
```

`makeUIViewController` is called on the main thread. `Data(contentsOf:)` is a blocking file read. A 5-minute recording can be 4–8 MB; on an older device this will freeze the UI for a visible moment. Use `addAttachmentURL(_:withAlternateFilename:)` or load data on a background queue before presenting.

---

## 🟡 Important

### 4. `Recording.duration` is always 0

`AVAudioRecorder.currentTime` gives elapsed recording time. `stopRecording()` never captures it, so every saved Recording has `duration = 0`. Add `var recordingDuration: TimeInterval` to AudioRecorder, populate it on stop, use it when constructing the Recording struct.

### 5. File rename collision in FreestyleRecordingView

If a user records two stories with the same name, `FileManager.moveItem` throws because the sanitized destination already exists. The recording is lost and a generic "Save Failed" alert appears. Add a UUID or timestamp suffix to the filename to prevent collisions.

### 6. `iCloudBackupEnabled` is a ghost feature

The flag is stored and surfaced in setup, but there is zero iCloud backup implementation. `Documents/Recordings/` is backed up by default by iOS regardless of this flag. Either implement it (`.isExcludedFromBackup`) or remove the flag before TestFlight — it misleads users.

### 7. `AVAudioSession.requestRecordPermission()` deprecated in iOS 17

The deployment target IS iOS 17 but `PermissionManager` still calls the deprecated `AVAudioSession` API. Update to `AVAudioApplication.requestRecordPermission()`.

### 8. Recording flow has no integration/UI tests

Unit tests for `StorageManager` and models are solid. But the core journey (permission check → record → stop → share) has zero test coverage. Flag for the next sprint.

---

## 🔵 TestFlight Readiness

| Item | Status | Notes |
|------|--------|-------|
| `DEVELOPMENT_TEAM` | ❌ Empty | Must be set before archiving |
| Privacy Manifest (`PrivacyInfo.xcprivacy`) | ❌ Missing | **Required by Apple since Apr 2024** for apps using UserDefaults, file system, contacts. Will be rejected without it. |
| App Icon | ⚠️ Unverified | Confirm `AppIcon` asset set is complete |
| Launch Screen assets | ⚠️ Risky | `Info.plist` references `LaunchBackground` color and `LaunchIcon` image — if missing from asset catalog, app crashes on launch |
| Privacy Policy URL | ❌ Missing | Required for App Store listing |
| Crash reporting | ❌ None | Consider adding at minimum before TestFlight |

### Minor
- `HomeView` hardcodes `Color(red: 0.3, green: 0.65, blue: 0.4)` instead of using `AppColors` — should get a token.
- `SetupView` struct in `ContentView.swift` is defined but never used (dead code).

---

## What's Working Well

- **Accessibility is genuinely good**: VoiceOver labels, hints, `accessibilityLiveRegion`, hidden decorative elements — better than most indie apps.
- **Interruption handling** (phone calls during recording) is implemented and exposed to the UI.
- **StorageManager is properly injectable** for testing with custom UserDefaults/FileManager.
- **Disk space check** before recording is a nice touch for this audience.
- **Error handling present throughout** — nearly every throwing call has a user-facing alert.
