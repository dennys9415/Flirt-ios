import Foundation

/// Shared storage between the app and the keyboard extension via App Groups.
///
/// v0.2 MVP: tokens live in App Group UserDefaults so the keyboard can reach
/// the API. Before TestFlight (v1.0) move tokens to a shared Keychain access
/// group — UserDefaults is not encrypted at rest.
enum AppGroupStore {
    static let groupId = "group.com.singularitybox.flirt"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupId) ?? .standard
    }

    static var accessToken: String? {
        get { defaults.string(forKey: "accessToken") }
        set { defaults.set(newValue, forKey: "accessToken") }
    }

    static var refreshToken: String? {
        get { defaults.string(forKey: "refreshToken") }
        set { defaults.set(newValue, forKey: "refreshToken") }
    }

    static var deviceIdentifier: String? {
        get { defaults.string(forKey: "deviceIdentifier") }
        set { defaults.set(newValue, forKey: "deviceIdentifier") }
    }

    static var selectedTone: Tone {
        get {
            defaults.string(forKey: "selectedTone").flatMap(Tone.init(rawValue:))
                ?? .lightFlirt
        }
        set { defaults.set(newValue.rawValue, forKey: "selectedTone") }
    }
}
