import SwiftUI

/// The main recording screen. Receives an optional prompt question.
struct RecordingView: View {
    var question: String? = nil
    var categoryId: String? = nil

    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var storage = StorageManager()
    @State private var isRecording = false
    @State private var recordingFinished = false
    @Environment(\.dismiss) private var dismiss

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
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(Color.green.gradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Record Your Story")
        .navigationBarTitleDisplayMode(.inline)
    }

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
            isRecording = true
        }
    }
}

#Preview {
    NavigationStack {
        RecordingView(question: "What is your earliest memory?", categoryId: "childhood")
    }
}
