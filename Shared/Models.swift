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
    /// BYOK: "user_key" | "system" (optional for older servers)
    let keySource: String?
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

// MARK: - v0.3: accounts, usage, history

struct EmailAuthRequest: Codable {
    /// email for register; email OR username for login
    var email: String?
    var username: String?
    let password: String
    let deviceIdentifier: String
}

struct AuthUser: Codable, Equatable {
    let id: String
    let email: String
    let username: String?
    let plan: String
}

struct AccountTokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let deviceId: String
    let user: AuthUser?
}

struct UserProfile: Codable, Equatable {
    let id: String
    let email: String
    let username: String?
    let displayName: String?
    let plan: String
    let historyOptIn: Bool
}

struct MeResponse: Codable {
    let user: UserProfile?
}

struct UpdateProfileRequest: Codable {
    var displayName: String?
    var historyOptIn: Bool?
}

struct UsageSummary: Codable, Equatable {
    let plan: String
    let used: Int
    let limit: Int?
    let enforced: Bool
    let resetsAt: String
}

struct HistoryEntry: Codable, Identifiable, Equatable {
    let id: String
    let message: String
    let tone: String
    let suggestions: [Suggestion]
    let createdAt: String
}

struct HistoryResponse: Codable {
    let entries: [HistoryEntry]
}

// MARK: - v0.4: subscriptions

struct VerifySubscriptionRequest: Codable {
    let transactionId: String
    let productId: String
    let environment: String
    let expiresAt: String?
}

struct VerifySubscriptionResponse: Codable {
    let plan: String
    let status: String
    let expiresAt: String?
}

// MARK: - v0.5: BYOK AI settings

enum AiProviderChoice: String, CaseIterable, Identifiable, Codable {
    case openai, anthropic, gemini

    var id: String { rawValue }

    var label: String {
        switch self {
        case .openai: return "OpenAI"
        case .anthropic: return "Claude (Anthropic)"
        case .gemini: return "Gemini (Google)"
        }
    }
}

struct UpsertAiSettingsRequest: Codable {
    let provider: String
    let apiKey: String
    let model: String?
}

struct AiSettingsView_DTO: Codable, Equatable {
    let provider: String
    let model: String?
    let apiKeyMasked: String
}

struct AiSettingsResponse: Codable {
    let settings: AiSettingsView_DTO?
}
