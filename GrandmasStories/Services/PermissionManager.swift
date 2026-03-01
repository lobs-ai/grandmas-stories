import AVFoundation
import UIKit
import Combine

/// Centralized manager for runtime permission requests.
final class PermissionManager: ObservableObject {

    // MARK: - Published State

    @Published private(set) var microphoneGranted: Bool = false

    // MARK: - Plain-Language Explanations

    let microphoneExplanation = "Grandma's Stories needs your microphone to record your personal stories for your family."
    let contactsExplanation = "Grandma's Stories can use your contacts to easily select family members to share stories with."

    // MARK: - Init

    init() {
        microphoneGranted = currentMicrophoneStatus() == .granted
    }

    // MARK: - Microphone

    /// Returns the current microphone permission status.
    func currentMicrophoneStatus() -> AVAudioSession.RecordPermission {
        AVAudioSession.sharedInstance().recordPermission
    }

    /// Requests microphone permission. Updates `microphoneGranted` on the main actor.
    func requestMicrophonePermission() async {
        let granted = await AVAudioSession.sharedInstance().requestRecordPermission()
        await MainActor.run {
            self.microphoneGranted = granted
        }
    }

    // MARK: - Settings

    /// Opens the app's Settings page so the user can change permissions.
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
