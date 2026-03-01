import SwiftUI
import AVFoundation

struct RecordingTestView: View {
    @EnvironmentObject var permissionManager: PermissionManager
    @StateObject private var audioRecorder = AudioRecorder()

    let onContinue: () -> Void

    // MARK: - State

    @State private var recordingState: RecordingState = .idle
    @State private var autoStopTimer: Timer?
    @State private var wavePhase: Double = 0
    @State private var showSilenceAlert = false
    @State private var showPermissionDeniedAlert = false
    @State private var silenceSampleCount = 0
    @State private var meterTimer: Timer?

    enum RecordingState {
        case idle, requesting, recording, playback, done
    }

    private let sampleSentence = "The leaves are turning gold and red, and the air smells like apple pie."

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                sentenceSection
                waveformSection
                controlSection
                skipSection
            }
            .padding(24)
        }
        .alert("We couldn't hear anything.", isPresented: $showSilenceAlert) {
            Button("Retry") { resetRecording() }
            Button("Continue Anyway") { onContinue() }
        } message: {
            Text("Please check that your device isn't muted and try again.")
        }
        .alert("Microphone Access Denied", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") { permissionManager.openAppSettings() }
            Button("Continue Anyway") { onContinue() }
        } message: {
            Text("Please enable microphone access in Settings to record stories.")
        }
        .onDisappear { cleanup() }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.purple)

            Text("Let's make sure your microphone works!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
        }
    }

    private var sentenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Please read this sentence aloud:")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(sampleSentence)
                .font(.system(size: 22, weight: .medium))
                .multilineTextAlignment(.leading)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var waveformSection: some View {
        if audioRecorder.isRecording {
            WaveformAnimationView(phase: $wavePhase)
                .frame(height: 60)
                .onAppear { startWaveAnimation() }
                .onDisappear { stopWaveAnimation() }
        } else if audioRecorder.isPlaying {
            Label("Playing back…", systemImage: "speaker.wave.2.fill")
                .font(.system(size: 18))
                .foregroundStyle(.purple)
        } else {
            Color.clear.frame(height: 60)
        }
    }

    private var controlSection: some View {
        VStack(spacing: 16) {
            switch recordingState {
            case .idle:
                primaryButton(title: "Start Recording", icon: "mic.fill", color: .purple) {
                    startRecording()
                }
            case .requesting:
                ProgressView("Requesting access…")
            case .recording:
                primaryButton(title: "Finish", icon: "stop.circle.fill", color: .red) {
                    stopAndPlay()
                }
                Text("Recording stops automatically after 20 seconds")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            case .playback:
                ProgressView("Playing back your recording…")
            case .done:
                primaryButton(title: "Continue", icon: "chevron.right.circle.fill", color: .green) {
                    onContinue()
                }
                Button("Retry") { resetRecording() }
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
            }
        }
    }

    private var skipSection: some View {
        Group {
            if recordingState == .idle {
                Button("Continue Anyway") { onContinue() }
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Helpers

    private func primaryButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: 22, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Recording Flow

    private func startRecording() {
        Task {
            recordingState = .requesting
            if permissionManager.currentMicrophoneStatus() != .granted {
                await permissionManager.requestMicrophonePermission()
            }
            guard permissionManager.microphoneGranted else {
                await MainActor.run {
                    recordingState = .idle
                    showPermissionDeniedAlert = true
                }
                return
            }

            await MainActor.run {
                do {
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent("recording-test.m4a")
                    try audioRecorder.startRecording(to: url)
                    recordingState = .recording
                    silenceSampleCount = 0

                    // Monitor silence
                    meterTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        checkSilence()
                    }

                    // Auto-stop after 20 seconds
                    autoStopTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { _ in
                        stopAndPlay()
                    }
                } catch {
                    recordingState = .idle
                }
            }
        }
    }

    private func checkSilence() {
        // Not relevant for silence after-recording check; we check after stop
    }

    private func stopAndPlay() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        meterTimer?.invalidate()
        meterTimer = nil

        // Check if there was any meaningful audio (file size > 5KB)
        let wasSilent: Bool
        if let url = audioRecorder.recordingURL,
           let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int {
            wasSilent = size < 5000
        } else {
            wasSilent = true
        }

        audioRecorder.stopRecording()
        stopWaveAnimation()

        if wasSilent {
            recordingState = .idle
            showSilenceAlert = true
            return
        }

        recordingState = .playback

        // Auto-play
        audioRecorder.playRecording()

        // Watch for playback end
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !audioRecorder.isPlaying {
                timer.invalidate()
                recordingState = .done
            }
        }
    }

    private func resetRecording() {
        cleanup()
        recordingState = .idle
        silenceSampleCount = 0
    }

    private func cleanup() {
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        meterTimer?.invalidate()
        meterTimer = nil
        if audioRecorder.isRecording { audioRecorder.stopRecording() }
        stopWaveAnimation()
    }

    // MARK: - Wave Animation

    private func startWaveAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            guard audioRecorder.isRecording else { timer.invalidate(); return }
            wavePhase += 0.15
        }
    }

    private func stopWaveAnimation() {
        wavePhase = 0
    }
}

// MARK: - Waveform View

struct WaveformAnimationView: View {
    @Binding var phase: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 4) {
                ForEach(0..<20, id: \.self) { i in
                    let amplitude = abs(sin(phase + Double(i) * 0.5)) * 0.8 + 0.2
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.purple)
                        .frame(
                            width: (geo.size.width / 20) - 4,
                            height: geo.size.height * amplitude
                        )
                        .frame(height: geo.size.height, alignment: .center)
                }
            }
        }
    }
}
