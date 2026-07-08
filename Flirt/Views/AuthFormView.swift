import SwiftUI

/// Reusable register/login form — used in Settings and Onboarding.
struct AuthFormView: View {
    var onSuccess: () -> Void

    @State private var isRegistering = true
    @State private var identifier = "" // login: email or username
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 10) {
            if isRegistering {
                field(TextField("Email", text: $email), contentType: .emailAddress)
                field(TextField("Username (optional)", text: $username), contentType: .username)
            } else {
                field(TextField("Email or username", text: $identifier), contentType: .username)
            }
            SecureField("Password (8+ characters)", text: $password)
                .textContentType(isRegistering ? .newPassword : .password)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
                submit()
            } label: {
                Group {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(isRegistering ? "Create account" : "Log in")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit)

            Button(
                isRegistering
                    ? "Already have an account? Log in"
                    : "New here? Create an account"
            ) {
                isRegistering.toggle()
                errorMessage = nil
            }
            .font(.footnote)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var canSubmit: Bool {
        guard password.count >= 8, !isSubmitting else { return false }
        return isRegistering ? email.contains("@") : !identifier.isEmpty
    }

    private func field(_ textField: TextField<Text>, contentType: UITextContentType) -> some View {
        textField
            .textContentType(contentType)
            .keyboardType(contentType == .emailAddress ? .emailAddress : .default)
            .autocapitalization(.none)
            .autocorrectionDisabled()
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func submit() {
        isSubmitting = true
        errorMessage = nil
        Task {
            defer { isSubmitting = false }
            do {
                if isRegistering {
                    _ = try await APIClient.shared.register(
                        email: email,
                        password: password,
                        username: username
                    )
                } else {
                    _ = try await APIClient.shared.login(
                        identifier: identifier,
                        password: password
                    )
                }
                password = ""
                onSuccess()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
