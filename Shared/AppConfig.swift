import Foundation

enum AppConfig {
    /// Local dev: the flirt-api stack from flirt-infra (scripts/up.sh).
    /// The iOS simulator reaches the host machine via localhost.
    static let apiBaseURL = URL(string: "http://localhost:3000")!
}
