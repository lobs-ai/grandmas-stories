# Grandma's Stories

An iOS app for recording and sharing personal family stories. Designed to help grandparents and older family members capture their memories in a simple, accessible way — and send them straight to the family.

Built as an experiment using a local AI model (Qwen 3.5 35B-A3B).

---

## Features

- 🎙️ **Guided recording** — Browse story prompt categories (childhood, family, wisdom, etc.) and record answers to curated questions
- 🎤 **Freestyle recording** — Record any story without a prompt
- 👨‍👩‍👧 **Family sharing** — Send recordings via iMessage or WhatsApp to configured family members
- ♿ **Accessibility first** — Full VoiceOver support, Dynamic Type, high-contrast colors, 44pt minimum tap targets
- 💾 **Persistent storage** — All recordings and settings survive app restarts

---

## Build Instructions

### Requirements

- Xcode 15 or later
- iOS 17+ deployment target
- A physical device (for microphone recording and sending messages)

### Steps

1. Clone the repo:
   ```bash
   git clone <repo-url>
   cd grandmas-stories
   ```
2. Open `GrandmasStories.xcodeproj` in Xcode
3. Select your team under **Signing & Capabilities**
4. Build and run on a device (`Cmd+R`)

> **Note:** Microphone permissions are required at runtime. The app will prompt when you first attempt to record.

---

## Screenshots

_Coming soon — placeholder section_

| Home | Record with Question | Freestyle | Share |
|------|---------------------|-----------|-------|
| _(screenshot)_ | _(screenshot)_ | _(screenshot)_ | _(screenshot)_ |

---

## Project Structure

```
GrandmasStories/
├── GrandmasStoriesApp.swift      # App entry point
├── Models/                       # Data models (Recording, FamilyMember, etc.)
├── Services/                     # AudioRecorder, StorageManager, SharingService, PermissionManager
├── Views/
│   ├── HomeView.swift
│   ├── ContentView.swift
│   ├── AppColors.swift           # Warm color tokens
│   ├── Recording/                # CategorySelectionView, QuestionView, RecordingView, FreestyleRecordingView
│   ├── Setup/                    # SetupContainerView, RecordingTestView, FamilySharingSetupView
│   └── Components/               # FamilyMemberRow, MessageComposer, ShareSheet
└── Data/
    └── QuestionBank.swift        # All story prompt categories and questions
```

---

## License

Personal / experimental project.
