import UIKit
import SwiftUI

/// Share Extension principal class.
///
/// Lifecycle:
///   1. viewDidLoad — async-extract contact from NSExtensionItem vCard payload
///   2. presentUI   — host ShareExtensionRootView in a UIHostingController
///   3. saveAndClose — write SharedPersonPayload to App Group, complete request
///   4. cancel       — cancel request, no side-effects
///
/// Design constraint: this class runs inside the extension sandbox.
/// It MUST NOT import or reference any main-app-only types (SwiftData models,
/// AnalyticsService, etc.). All dependencies are sourced from shared files
/// that belong to both targets.
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    private var extractionResult: SharedContactExtractor.ExtractionResult?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        Task {
            let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
            let result = await SharedContactExtractor.extract(from: items)
            self.extractionResult = result
            await MainActor.run {
                presentUI(displayName: result?.displayName ?? "Contact")
            }
        }
    }

    // MARK: - UI

    private func presentUI(displayName: String) {
        let rootView = ShareExtensionRootView(
            displayName: displayName,
            onSave: { [weak self] note in self?.saveAndClose(noteText: note) },
            onCancel: { [weak self] in self?.cancel() }
        )

        let host = UIHostingController(rootView: rootView)
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }

    // MARK: - Actions

    private func saveAndClose(noteText: String) {
        let payload = SharedPersonPayload(
            displayName: extractionResult?.displayName ?? "Unknown",
            contactIdentifier: extractionResult?.contactIdentifier,
            noteText: noteText.isEmpty ? nil : noteText
        )
        ShareExtensionStore.savePayload(payload)
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(
            withError: NSError(domain: "com.freshtie.share", code: 0, userInfo: nil)
        )
    }
}
