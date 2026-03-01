import SwiftUI
import MessageUI

/// UIViewControllerRepresentable wrapping MFMessageComposeViewController for iMessage sharing.
struct MessageComposer: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String
    let attachmentURL: URL?
    var onCompletion: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.recipients = recipients
        vc.body = body
        vc.messageComposeDelegate = context.coordinator

        if let url = attachmentURL,
           let data = try? Data(contentsOf: url) {
            let mimeType = url.pathExtension.lowercased() == "m4a" ? "audio/x-m4a" : "audio/mpeg"
            vc.addAttachmentData(data, typeIdentifier: mimeType, filename: url.lastPathComponent)
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    // MARK: - Coordinator

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onCompletion: (() -> Void)?

        init(onCompletion: (() -> Void)?) {
            self.onCompletion = onCompletion
        }

        func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            controller.dismiss(animated: true)
            if result == .sent {
                onCompletion?()
            }
        }
    }
}
