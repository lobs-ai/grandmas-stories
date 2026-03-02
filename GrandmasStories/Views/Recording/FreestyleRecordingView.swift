import SwiftUI
import MessageUI

/// Freestyle recording flow — no category or question prompt.
struct FreestyleRecordingView: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var storage = StorageManager()
    @StateObject private var sharingService = SharingService()
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var isRecording = false
    @State private var recordingFinished = false
    @State private var showNamingDialog = false
    @State private var storyName = ""
    @State private var savedRecording: Recording? = nil
    @State private var savedAudioURL: URL? = nil
    @State private var showSharingOptions = false
    @State private var showPermissionDeniedAlert = false
    @State private var showDiskSpaceAlert = false
    @State private var showInterruptionAlert = false
    @State private var showSaveFailedAlert = false

    @Environment(\.dismiss) private var dismiss

    private var settingsStore = SettingsStore()

    @ViewBuilder
    private var headerCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.freestyleAccent)
                .accessibilityHidden(true)
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
    }

    @ViewBuilder
    private var recordingIndicator: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red.opacity(0.15) : AppColors.freestyleAccent.opacity(0.1))
                .frame(width: 140, height: 140)
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 52))
                .foregroundStyle(isRecording ? .red : AppColors.freestyleAccent)
                .symbolEffect(.pulse, isActive: isRecording)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 14) {
            if !recordingFinished {
                let bg = isRecording ? Color.red.gradient : AppColors.freestyleAccent.gradient
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
                .accessibilityHint(isRecording ? "Tap to stop and save your story" : "Tap to begin recording your freestyle story")
            } else {
                Button(action: { showSharingOptions = true }) {
                    Label("Share Story", systemImage: "square.and.arrow.up")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(AppColors.freestyleAccent.gradient)
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

    var body: some View {
        withOverlays(VStack(spacing: 32) {
            Spacer()

            headerCard

            recordingIndicator

            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            actionButtons
        }
        .navigationTitle("Freestyle Story")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: audioRecorder.wasInterrupted) { interrupted in
            if interrupted {
                isRecording = false
                showInterruptionAlert = true
            }
        }
        )
    }

    private func withOverlays<V: View>(_ content: V) -> some View {
        content
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
            showNamingDialog = true
        } else {
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
            if AudioRecorder.isDiskSpaceLow() {
                showDiskSpaceAlert = true
                return
            }
            startRecording()
        }
    }

    private func startRecording() {
        let tempName = "freestyle_tmp_\(UUID().uuidString).m4a"
        let url = storage.audioFileURL(fileName: tempName)
        do {
            try storage.ensureAudioDirectoryExists()
            try audioRecorder.startRecording(to: url)
            savedAudioURL = url
            isRecording = true
        } catch {
            showSaveFailedAlert = true
        }
    }

    private func saveRecording() {
        guard let tmpURL = savedAudioURL else { return }

        let name = storyName.trimmingCharacters(in: .whitespaces)
        let sanitized = sanitize(name.isEmpty ? "untitled" : name)
        let fileName = "family_history_freestyle_\(sanitized).m4a"
        let destURL = storage.audioFileURL(fileName: fileName)

        do {
            try FileManager.default.moveItem(at: tmpURL, to: destURL)
        } catch {
            showSaveFailedAlert = true
            return
        }

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
    .environmentObject(PermissionManager())
}
