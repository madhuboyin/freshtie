import SwiftUI
import Contacts
import ContactsUI

/// Bridges CNContactPickerViewController into SwiftUI.
///
/// Present this as a `.sheet`. The system picker is displayed immediately
/// over a transparent host view, so the caller's sheet dismisses cleanly
/// when either `onSelect` or `onCancel` fires.
struct ContactPickerRepresentable: UIViewControllerRepresentable {
    let onSelect: (CNContact) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ContactPickerHost {
        let host = ContactPickerHost()
        host.onSelect = onSelect
        host.onCancel = onCancel
        return host
    }

    func updateUIViewController(_ uiViewController: ContactPickerHost, context: Context) {}
}

// MARK: - Host controller

/// Minimal UIViewController that presents CNContactPickerViewController on appear.
/// The picker dismisses itself after selection or cancellation; we relay both callbacks.
final class ContactPickerHost: UIViewController, CNContactPickerDelegate {
    var onSelect: ((CNContact) -> Void)?
    var onCancel: (() -> Void)?

    private var didPresent = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Transparent so the host is invisible when the picker finishes dismissing.
        view.backgroundColor = .clear
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresent else { return }
        didPresent = true

        let picker = CNContactPickerViewController()
        picker.delegate = self
        // No animation so the user lands directly in the picker.
        present(picker, animated: false)
    }

    // MARK: CNContactPickerDelegate

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        onSelect?(contact)
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        onCancel?()
    }
}
