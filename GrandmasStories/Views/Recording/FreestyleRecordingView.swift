import SwiftUI
import MessageUI

/// Freestyle recording flow — no category or question prompt.
/// After recording, asks the user to name the story before sharing.
struct FreestyleRecordingView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var storage = StorageManager()
    @StateObject private var sharingService = SharingService()

    @State private var isRecording = false
    @State private var recordingFinished = false
    @State private var showNamingDialog = false
    @State private var storyName = ""
    @State private var savedRecording: Recording? = nil
    @State private var savedAudioURL: URL? = nil
    @State private var showSharingOptions = false

    @Environment(\.dismiss) private var dismiss

    private var settingsStore = SettingsStore()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Encouraging prompt instead of a question card
            VStack(spacing: 8) {
                Image(systemName: "heart.text.square")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)
                Text("Tell us whatever story is on your mind!")
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 24)

            // Recording indicator
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.15) : Color.purple.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(isRecording ? .red : .purple)
                    .symbolEffect(.pulse, isActive: isRecording)
            }

            Text(isRecording ? "Recording..." : (recordingFinished ? "Recording saved!" : "Tap to start"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 14) {
                if !recordingFinished {
                    Button(action: toggleRecording) {
                        Text(isRecording ? "Stop Recording" : "Start Recording")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(isRecording ? Color.red.gradient : Color.purple.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                } else {
                    Button(action: { showSharingOptions = true }) {
                        Label("Share Story", systemImage: "square.and.arrow.up")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.purple.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Freestyle Story")
        .navigationBarTitleDisplayMode(.inline)
        .alert("What should we call this story?", isPresented: $showNamingDialog) {
            TextField("e.g., The time I met your grandfather", text: $storyName)
            Button("Save") { saveRecording() }
            Button("Cancel", role: .cancel) {
                recordingFinished = false
                savedAudioURL = nil
            }
        }
        .confirmationDialog("Share via", isPresented: $showSharingOptions, titleVisibility: .visible) {
            Button("iMessage") { triggerShare(method: .iMessage) }
            Button("WhatsApp") { triggerShare(method: .whatsApp) }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $sharingService.showShareSheet) {
            ShareSheet(items: sharingService.shareItems) {
                markSharedAndDismiss()
            }
        }
        .sheet(isPresented: $sharingService.showMessageComposer) {
            if let url = sharingService.messageAttachmentURL {
                MessageComposer(
                    recipients: sharingService.messageRecipients,
                    body: sharingService.messageBody,
                    attachmentURL: url
                ) {
                    markSharedAndDismiss()
                }
            }
        }
        .alert(sharingService.alertTitle, isPresented: $sharingService.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sharingService.alertMessage)
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            showNamingDialog = true
        } else {
            let tempName = "freestyle_tmp_\(UUID().uuidString).m4a"
            let url = storage.audioFileURL(fileName: tempName)
            try? storage.ensureAudioDirectoryExists()
            try? audioRecorder.startRecording(to: url)
            savedAudioURL = url
            isRecording = true
        }
    }

    private func saveRecording() {
        guard let tmpURL = savedAudioURL else { return }

        let name = storyName.trimmingCharacters(in: .whitespaces)
        let sanitized = sanitize(name.isEmpty ? "untitled" : name)
        let fileName = "family_history_freestyle_\(sanitized).m4a"
        let destURL = storage.audioFileURL(fileName: fileName)

        try? FileManager.default.moveItem(at: tmpURL, to: destURL)

        let recording = Recording(
            title: name.isEmpty ? "Freestyle Story" : name,
            categoryId: nil,
            questionText: nil,
            fileName: fileName
        )
        savedRecording = recording
        savedAudioURL = destURL
        recordingFinished = true
    }

    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        return name
            .lowercased()
            .components(separatedBy: allowed.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
    }

    private func triggerShare(method: SharingMethod) {
        guard let recording = savedRecording, let url = savedAudioURL else { return }
        let members = settingsStore.settings.familyMembers
        sharingService.shareRecording(recording, via: method, to: members, audioURL: url) {
            markSharedAndDismiss()
        }
    }

    private func markSharedAndDismiss() {
        if var rec = savedRecording {
            rec.sharedAt = Date()
            storage.saveRecording(rec)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FreestyleRecordingView()
    }
}
