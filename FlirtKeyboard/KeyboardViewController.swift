import SwiftUI
import UIKit

/// Flirt Keyboard — suggestion keyboard (v0.2 MVP).
///
/// Constraints (see flirt-docs/IOS_KEYBOARD_RULES.md):
/// - Network requires the user to enable "Allow Full Access".
/// - Strict memory budget: no heavy assets, work happens on the backend.
/// - The received message comes from the clipboard (keyboards cannot read the
///   host app's conversation) with the text field content as fallback.
final class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        Task { await APIClient.shared.configureForExtension() }

        let keyboardView = KeyboardView(
            hasFullAccess: hasFullAccess,
            needsGlobe: needsInputModeSwitchKey,
            actions: KeyboardActions(
                insertText: { [weak self] text in
                    self?.textDocumentProxy.insertText(text)
                },
                contextText: { [weak self] in
                    self?.textDocumentProxy.documentContextBeforeInput
                },
                switchKeyboard: { [weak self] in
                    self?.advanceToNextInputMode()
                }
            )
        )

        let host = UIHostingController(rootView: keyboardView)
        hostingController = host
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.heightAnchor.constraint(equalToConstant: 300),
        ])
        host.didMove(toParent: self)
    }
}

/// Bridge between SwiftUI and UIInputViewController capabilities.
struct KeyboardActions {
    let insertText: (String) -> Void
    let contextText: () -> String?
    let switchKeyboard: () -> Void
}
