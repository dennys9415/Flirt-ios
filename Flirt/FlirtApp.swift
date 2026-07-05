import SwiftUI

@main
struct FlirtApp: App {
    var body: some Scene {
        WindowGroup {
            ReplyGeneratorView()
                .task {
                    // Provision the device identity so the keyboard is ready
                    await APIClient.shared.warmUp()
                }
        }
    }
}
