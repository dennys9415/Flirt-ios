import Foundation
import UIKit

enum APIError: LocalizedError {
    case http(Int, String)
    case decoding
    case network(Error)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .http(let status, let message):
            return "\(message) (\(status))"
        case .decoding:
            return "Unexpected server response"
        case .network:
            return "Can't reach the server — is it running?"
        case .notAuthenticated:
            return "Open the Flirt app once to set up"
        }
    }
}

/// Thin client for flirt-api, shared by the app and the keyboard extension.
/// Tokens persist in the App Group so both targets share one device identity.
actor APIClient {
    static let shared = APIClient()

    /// The keyboard extension must not create a device identity — the app owns
    /// onboarding. Set `false` there so an un-set-up keyboard fails with
    /// `.notAuthenticated` instead of registering a parallel device.
    var allowsDeviceRegistration = true

    func configureForExtension() {
        allowsDeviceRegistration = false
    }

    private let baseURL = AppConfig.apiBaseURL
    private var accessToken: String? = AppGroupStore.accessToken

    // MARK: - Public API

    /// Called by the app at launch so the keyboard extension finds a ready
    /// token in the App Group without the user generating anything first.
    func warmUp() async {
        _ = try? await ensureToken()
    }

    func generateReplies(message: String, tone: Tone) async throws -> GenerateRepliesResponse {
        try await authorizedPost(
            path: "/ai/replies",
            body: GenerateRepliesRequest(message: message, tone: tone.rawValue, intent: "reply")
        )
    }

    func refine(text: String, action: RefineAction) async throws -> RefineResponse {
        try await authorizedPost(
            path: "/ai/refine",
            body: RefineRequest(text: text, action: action.rawValue)
        )
    }

    // MARK: - Auth

    private func ensureToken() async throws -> String {
        if let token = accessToken { return token }
        if let stored = AppGroupStore.accessToken {
            accessToken = stored
            return stored
        }
        return try await authenticateDevice()
    }

    private func authenticateDevice() async throws -> String {
        guard allowsDeviceRegistration || AppGroupStore.deviceIdentifier != nil else {
            throw APIError.notAuthenticated
        }
        let identifier = await deviceIdentifier()
        let response: TokenPairResponse = try await post(
            path: "/auth/device",
            body: DeviceAuthRequest(deviceIdentifier: identifier, platform: "ios"),
            token: nil
        )
        accessToken = response.accessToken
        AppGroupStore.accessToken = response.accessToken
        AppGroupStore.refreshToken = response.refreshToken
        return response.accessToken
    }

    @MainActor
    private func deviceIdentifier() -> String {
        if let existing = AppGroupStore.deviceIdentifier { return existing }
        let fresh = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        AppGroupStore.deviceIdentifier = fresh
        return fresh
    }

    // MARK: - Transport

    private func authorizedPost<B: Encodable, R: Decodable>(path: String, body: B) async throws -> R {
        let token = try await ensureToken()
        do {
            return try await post(path: path, body: body, token: token)
        } catch APIError.http(401, _) {
            // Expired token — re-authenticate once and retry
            accessToken = nil
            AppGroupStore.accessToken = nil
            let fresh = try await authenticateDevice()
            return try await post(path: path, body: body, token: fresh)
        }
    }

    private func post<B: Encodable, R: Decodable>(path: String, body: B, token: String?) async throws -> R {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        guard (200..<300).contains(http.statusCode) else {
            let parsed = try? JSONDecoder().decode(ApiErrorBody.self, from: data)
            let message = parsed?.error?.message ?? parsed?.message ?? "Request failed"
            throw APIError.http(http.statusCode, message)
        }
        guard let decoded = try? JSONDecoder().decode(R.self, from: data) else {
            throw APIError.decoding
        }
        return decoded
    }
}
