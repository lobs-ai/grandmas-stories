import AVFoundation
import Combine

/// ObservableObject wrapper around AVAudioRecorder and AVAudioPlayer.
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    // MARK: - Published State

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    @Published var silenceDetected = false

    // MARK: - Private

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?
    private let silenceThreshold: Float = -40.0 // dBFS

    // MARK: - Recording

    func startRecording(to url: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        recorder?.record()

        recordingURL = url
        isRecording = true
        silenceDetected = false

        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMeters()
        }
    }

    func stopRecording() {
        meterTimer?.invalidate()
        meterTimer = nil
        recorder?.stop()
        recorder = nil
        isRecording = false
    }

    func playRecording() {
        guard let url = recordingURL else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    // MARK: - Silence Detection

    private func checkMeters() {
        guard let recorder else { return }
        recorder.updateMeters()
        _ = recorder.averagePower(forChannel: 0)
    }

    /// Returns current average power in dBFS (call while recording).
    func currentAveragePower() -> Float {
        recorder?.updateMeters()
        return recorder?.averagePower(forChannel: 0) ?? -160
    }

    func isSilent() -> Bool {
        currentAveragePower() < silenceThreshold
    }

    // MARK: - Delegates

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
