import SwiftUI
import MessageUI

/// The main recording screen. Receives an optional prompt question.
struct RecordingView: View {
    var question: String? = nil
    var categoryId: String? = nil

    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var storage = StorageManager()
    @StateObject private var sharingService = SharingService()
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var isRecording = false
    @State private var recordingFinished = false
    @State private var savedRecording: Recording? = nil
    @State private var savedAudioURL: URL? = nil
    @State private var showSharingOptions = false
    @State private var showPermissionDeniedAlert = false
    @State private var showDiskSpaceAlert = false
    @State private var showInterruptionAlert = false
    @State private var showSaveFailedAlert = false

    @Environment(\.dismiss) private var dismiss

    private var settingsStore = SettingsStore()

    init(question: String? = nil, categoryId: String? = nil) {
        self.question = question
        self.categoryId = categoryId
    }

    // MARK: - Subviews

    @ViewBuilder
    private var questionCard: some View {
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
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Question: \(question)")
        }
    }

    @ViewBuilder
    private var recordingIndicator: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red.opacity(0.15) : AppColors.warmOrange.opacity(0.1))
                .frame(width: 140, height: 140)
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 52))
                .foregroundStyle(isRecording ? .red : AppColors.warmOrange)
                .symbolEffect(.pulse, isActive: isRecording)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 14) {
            if !recordingFinished {
                let bg = isRecording ? Color.red.gradient : AppColors.warmOrange.gradient
                Button(action: toggleRecording) {
                    Text(isRecording ? "Stop Recording" : "Start Recording")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(bg)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
                .accessibilityHint(isRecording ? "Tap to stop and save your recording" : "Tap to begin recording your story")
            } else {
                Button(action: { showSharingOptions = true }) {
                    Label("Share Story", systemImage: "square.and.arrow.up")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppColors.warmOrange.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .accessibilityLabel("Share your story")
                .accessibilityHint("Choose how to send this recording to your family")

                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .padding(.horizontal, 24)
                .accessibilityLabel("Done")
                .accessibilityHint("Return to the home screen")
            }
        }
        .padding(.bottom, 32)
    }

    private func withOverlays<V: View>(_ content: V) -> some View {
        content
            .confirmationDialog("Share via", isPresented: $showSharingOptions, titleVisibility: .visible) {
                Button("iMessage") { triggerShare(method: .iMessage) }
                Button("WhatsApp") { triggerShare(method: .whatsApp) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $sharingService.showShareSheet) {
                ShareSheet(items: sharingService.shareItems) { markSharedAndDismiss() }
            }
            .sheet(isPresented: $sharingService.showMessageComposer) {
                if let url = sharingService.messageAttachmentURL {
                    MessageComposer(
                        recipients: sharingService.messageRecipients,
                        body: sharingService.messageBody,
                        attachmentURL: url
                    ) { markSharedAndDismiss() }
                }
            }
            .alert("Microphone Access Needed", isPresented: $showPermissionDeniedAlert) {
                Button("Open Settings") { permissionManager.openAppSettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Grandma's Stories needs microphone access to record your stories. Please enable it in Settings.")
            }
            .alert("Storage Almost Full", isPresented: $showDiskSpaceAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your device is running low on storage. Please free up some space before recording.")
            }
            .alert("Recording Stopped", isPresented: $showInterruptionAlert) {
                Button("Record Again") { }
                Button("Done", role: .cancel) { dismiss() }
            } message: {
                Text("Your recording was interrupted (for example, by a phone call). Please try recording again.")
            }
            .alert("Save Failed", isPresented: $showSaveFailedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("We couldn't save your recording. Please check your storage and try again.")
            }
            .alert(sharingService.alertTitle, isPresented: $sharingService.showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(sharingService.alertMessage)
            }
    }

    var body: some View {
        withOverlays(
            VStack(spacing: 32) {
                Spacer()
                questionCard
                recordingIndicator
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                actionButtons
            }
            .navigationTitle("Record Your Story")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: audioRecorder.wasInterrupted) { interrupted in
                if interrupted {
                    isRecording = false
                    showInterruptionAlert = true
                }
            }
        )
    }

    // MARK: - Helpers

    private var statusText: String {
        if isRecording { return "Recording…" }
        if recordingFinished { return "Recording saved!" }
        return "Tap to start"
    }

    // MARK: - Actions

    private func toggleRecording() {
        if isRecording {
            audioRecorder.stopRecording()
            isRecording = false
            recordingFinished = true
        } else {
            // Check permission
            let status = permissionManager.currentMicrophoneStatus()
            if status == .denied || status == .undetermined {
                Task {
                    await permissionManager.requestMicrophonePermission()
                    if !permissionManager.microphoneGranted {
                        showPermissionDeniedAlert = true
                    } else {
                        startRecording()
                    }
                }
                return
            }
            if !permissionManager.microphoneGranted {
                showPermissionDeniedAlert = true
                return
            }

            // Check disk space
            if AudioRecorder.isDiskSpaceLow() {
                showDiskSpaceAlert = true
                return
            }

            startRecording()
        }
    }

    private func startRecording() {
        let fileName = "story_\(UUID().uuidString).m4a"
        let url = storage.audioFileURL(fileName: fileName)
        do {
            try storage.ensureAudioDirectoryExists()
            try audioRecorder.startRecording(to: url)
            savedAudioURL = url
            savedRecording = Recording(
                title: question ?? "Story",
                categoryId: categoryId,
                questionText: question,
                fileName: fileName
            )
            isRecording = true
        } catch {
            showSaveFailedAlert = true
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
    .environmentObject(PermissionManager())
}
