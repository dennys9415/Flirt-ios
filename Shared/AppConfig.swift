import Foundation

enum AppConfig {
    /// Simulator talks to the local stack (Flirt-infra/scripts/up.sh);
    /// a real device talks to production.
    static let apiBaseURL: URL = {
        #if targetEnvironment(simulator)
        URL(string: "http://localhost:3000")!
        #else
        URL(string: "https://api.thesingularitybox.com")!
        #endif
    }()
}
