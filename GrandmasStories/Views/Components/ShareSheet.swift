import SwiftUI
import UIKit

/// UIViewControllerRepresentable wrapping UIActivityViewController for WhatsApp / general sharing.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onCompletion: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, completed, _, _ in
            if completed {
                onCompletion?()
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
