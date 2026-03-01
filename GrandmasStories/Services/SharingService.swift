import Foundation
import UIKit
import MessageUI

// MARK: - SharingService

@MainActor
class SharingService: NSObject, ObservableObject {
    static let appName = "Grandma's Stories"
    static let shareMessage = "Here's a new story from \(appName)! 🎙️"

    @Published var showShareSheet = false
    @Published var showMessageComposer = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    /// Shared items for UIActivityViewController (WhatsApp / general share)
    var shareItems: [Any] = []

    /// Recipients and body for MFMessageComposeViewController
    var messageRecipients: [String] = []
    var messageBody = shareMessage
    var messageAttachmentURL: URL?

    private var onSharingComplete: (() -> Void)?

    // MARK: - Public API

    /// Primary entry point. Resolves to iMessage or WhatsApp flow.
    func shareRecording(
        _ recording: Recording,
        via method: SharingMethod,
        to members: [FamilyMember],
        audioURL: URL,
        onComplete: (() -> Void)? = nil
    ) {
        self.onSharingComplete = onComplete

        switch method {
        case .iMessage:
            shareViaIMessage(recording: recording, to: members, audioURL: audioURL)
        case .whatsApp:
            shareViaWhatsApp(recording: recording, to: members, audioURL: audioURL)
        }
    }

    // MARK: - iMessage

    private func shareViaIMessage(recording: Recording, to members: [FamilyMember], audioURL: URL) {
        guard MFMessageComposeViewController.canSendText() else {
            presentAlert(
                title: "iMessage Not Available",
                message: "iMessage is not set up on this device. Try sharing via WhatsApp instead."
            )
            return
        }

        let recipients = members.compactMap { $0.phoneNumber }.filter { !$0.isEmpty }
        if recipients.isEmpty {
            presentAlert(
                title: "No Recipients",
                message: "No family members have phone numbers configured. Go to Settings to add family members."
            )
            return
        }

        messageRecipients = recipients
        messageBody = Self.shareMessage
        messageAttachmentURL = audioURL
        showMessageComposer = true
    }

    // MARK: - WhatsApp

    private func shareViaWhatsApp(recording: Recording, to members: [FamilyMember], audioURL: URL) {
        // Try direct whatsapp:// URL scheme first (document share)
        let whatsappScheme = URL(string: "whatsapp://app")!
        if UIApplication.shared.canOpenURL(whatsappScheme) {
            shareItems = [audioURL, Self.shareMessage]
            showShareSheet = true
        } else {
            // WhatsApp not installed — fallback to general share sheet
            shareItems = [audioURL, Self.shareMessage]
            showShareSheet = true
            // Inform user
            presentAlert(
                title: "WhatsApp Not Installed",
                message: "WhatsApp doesn't appear to be installed. The general share sheet has been opened instead — you can also try iMessage."
            )
        }
    }

    // MARK: - Post-sharing

    /// Called by the UI wrappers when sharing completes.
    func didCompleteSharing() {
        onSharingComplete?()
    }

    // MARK: - Helpers

    private func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
