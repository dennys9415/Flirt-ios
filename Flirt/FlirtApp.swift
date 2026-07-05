import SwiftUI

@main
struct FlirtApp: App {
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasOnboarded {
                    MainTabView()
                } else {
                    OnboardingView { hasOnboarded = true }
                }
            }
            .task {
                // Provision the device identity so the keyboard is ready
                await APIClient.shared.warmUp()
            }
        }
    }
}
