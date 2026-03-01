import SwiftUI
import MessageUI

/// The main recording screen. Receives an optional prompt question.
struct RecordingView: View {
    var question: String? = nil
    var categoryId: String? = nil

    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var storage = StorageManager()
    @StateObject private var sharingService = SharingService()

    @State private var isRecording = false
    @State private var recordingFinished = false
    @State private var savedRecording: Recording? = nil
    @State private var savedAudioURL: URL? = nil
    @State private var showSharingOptions = false

    @Environment(\.dismiss) private var dismiss

    // Settings for family members / sharing method
    private var settingsStore = SettingsStore()

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            if let question = question {
                VStack(spacing: 12) {
                    Text("Your Question")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(question)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }

            // Recording indicator
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red.opacity(0.15) : Color.gray.opacity(0.1))
                    .frame(width: 140, height: 140)

                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(isRecording ? .red : .gray)
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
                            .background(isRecording ? Color.red.gradient : Color.blue.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Share button
                    Button(action: { showSharingOptions = true }) {
                        Label("Share Story", systemImage: "square.and.arrow.up")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.blue.gradient)
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
        .navigationTitle("Record Your Story")
        .navigationBarTitleDisplayMode(.inline)
        // Sharing options sheet
        .confirmationDialog("Share via", isPresented: $showSharingOptions, titleVisibility: .visible) {
            Button("iMessage") { triggerShare(method: .iMessage) }
            Button("WhatsApp") { triggerShare(method: .whatsApp) }
            Button("Cancel", role: .cancel) {}
        }
        // UIActivityViewController (WhatsApp / general)
        .sheet(isPresented: $sharingService.showShareSheet) {
            ShareSheet(items: sharingService.shareItems) {
                markSharedAndDismiss()
            }
        }
        // MFMessageComposeViewController (iMessage)
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
        // Error alerts
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
            recordingFinished = true
        } else {
            let fileName = "story_\(UUID().uuidString).m4a"
            let url = storage.audioFileURL(fileName: fileName)
            try? storage.ensureAudioDirectoryExists()
            try? audioRecorder.startRecording(to: url)

            // Prepare a Recording model for later sharing
            savedAudioURL = url
            savedRecording = Recording(
                title: question ?? "Story",
                categoryId: categoryId,
                questionText: question,
                fileName: fileName
            )
            isRecording = true
        }
    }

    private func triggerShare(method: SharingMethod) {
        guard let recording = savedRecording, let url = savedAudioURL else { return }
        let members = settingsStore.settings.familyMembers
        sharingService.shareRecording(recording, via: method, to: members, audioURL: url) {
            markSharedAndDismiss()
        }
    }

    private func markSharedAndDismiss() {
        // Persist sharedAt on the recording
        if var rec = savedRecording {
            rec.sharedAt = Date()
            storage.saveRecording(rec)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        RecordingView(question: "What is your earliest memory?", categoryId: "childhood")
    }
}
