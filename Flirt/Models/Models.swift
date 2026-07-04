import Foundation

// Mirrors the API contract — see flirt-docs/API_ENDPOINTS.md.
// Extracted to flirt-contracts once the API stabilizes.

enum Tone: String, CaseIterable, Identifiable, Codable {
    case lightFlirt = "light_flirt"
    case deepFlirt = "deep_flirt"
    case funny
    case confident
    case professional

    var id: String { rawValue }

    var label: String {
        switch self {
        case .lightFlirt: return "✨ Light Flirt"
        case .deepFlirt: return "🔥 Deep Flirt"
        case .funny: return "😂 Funny"
        case .confident: return "💪 Confident"
        case .professional: return "💼 Professional"
        }
    }
}

enum RefineAction: String, CaseIterable, Identifiable, Codable {
    case shorter
    case funnier
    case moreDirect = "more_direct"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .shorter: return "Shorter"
        case .funnier: return "Funnier"
        case .moreDirect: return "More Direct"
        }
    }
}

struct Suggestion: Codable, Identifiable, Equatable {
    var text: String
    let style: String

    var id: String { style + text }
}

// MARK: - Request/response payloads

struct DeviceAuthRequest: Codable {
    let deviceIdentifier: String
    let platform: String
}

struct TokenPairResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let deviceId: String
}

struct GenerateRepliesRequest: Codable {
    let message: String
    let tone: String
    let intent: String
}

struct GenerateRepliesResponse: Codable {
    let tone: String
    let intent: String
    let suggestions: [Suggestion]
    let provider: String
    let model: String
}

struct RefineRequest: Codable {
    let text: String
    let action: String
}

struct RefineResponse: Codable {
    let text: String
    let style: String
}

struct ApiErrorBody: Codable {
    struct Detail: Codable {
        let code: String?
        let message: String?
    }
    let error: Detail?
    let message: String?
}
