import AVFoundation
import Combine

/// ObservableObject wrapper around AVAudioRecorder and AVAudioPlayer.
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    // MARK: - Published State

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    @Published var silenceDetected = false
    @Published var wasInterrupted = false   // true if a phone call/etc stopped recording

    // MARK: - Private

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var meterTimer: Timer?
    private let silenceThreshold: Float = -40.0 // dBFS
    private var interruptionObserver: NSObjectProtocol?

    // MARK: - Init / Deinit

    override init() {
        super.init()
        observeAudioInterruptions()
    }

    deinit {
        if let obs = interruptionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

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
        wasInterrupted = false
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

    func currentAveragePower() -> Float {
        recorder?.updateMeters()
        return recorder?.averagePower(forChannel: 0) ?? -160
    }

    func isSilent() -> Bool {
        currentAveragePower() < silenceThreshold
    }

    // MARK: - Interruption Handling

    private func observeAudioInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            // A phone call or other interruption started — stop recording gracefully
            if isRecording {
                stopRecording()
                wasInterrupted = true
            }
        case .ended:
            // Interruption ended; we don't auto-resume — let the user decide
            break
        @unknown default:
            break
        }
    }

    // MARK: - Disk Space

    /// Returns available disk space in bytes, or nil if unavailable.
    static func availableDiskSpaceBytes() -> Int64? {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            return attrs[.systemFreeSize] as? Int64
        } catch {
            return nil
        }
    }

    /// Returns true if disk space is critically low (< 50 MB).
    static func isDiskSpaceLow() -> Bool {
        guard let free = availableDiskSpaceBytes() else { return false }
        return free < 50 * 1024 * 1024
    }

    // MARK: - Delegates

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
