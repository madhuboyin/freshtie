import UIKit
import Social
import SwiftUI

@objc(ShareViewController)
class ShareViewController: UIViewController {

    private var extractionResult: SharedContactExtractor.ExtractionResult?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Show a loading view or nothing until extraction completes
        view.backgroundColor = .clear
        
        Task {
            if let result = await SharedContactExtractor.extract(from: extensionContext?.inputItems as? [NSExtensionItem] ?? []) {
                self.extractionResult = result
                await MainActor.run {
                    showRootView(displayName: result.displayName)
                }
            } else {
                // If extraction fails, we still show the UI but with a generic title or close
                await MainActor.run {
                    showRootView(displayName: "Contact")
                }
            }
        }
    }

    private func showRootView(displayName: String) {
        let rootView = ShareExtensionRootView(
            displayName: displayName,
            onSave: { [weak self] note in
                self?.saveAndClose(noteText: note)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }

    private func saveAndClose(noteText: String) {
        let payload = SharedPersonPayload(
            displayName: extractionResult?.displayName ?? "Unknown",
            contactIdentifier: extractionResult?.contactIdentifier,
            noteText: noteText.isEmpty ? nil : noteText
        )
        
        AnalyticsService.shared.track(.share_extension_used, metadata: [
            AnalyticsMetadata.personID: extractionResult?.contactIdentifier ?? "unknown"
        ])
        
        ShareExtensionStore.savePayload(payload)
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "UserCancelled", code: 0))
    }
}
