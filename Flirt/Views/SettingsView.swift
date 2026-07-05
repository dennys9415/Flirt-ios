import SwiftUI

struct SettingsView: View {
    @State private var profile: UserProfile?
    @State private var usage: UsageSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Auth form
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isSubmitting = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                if profile != nil {
                    historySection
                }
                usageSection
                aboutSection
            }
            .navigationTitle("Settings")
            .task { await load() }
            .refreshable { await load() }
            .sheet(isPresented: $showPaywall) {
                PaywallView {
                    Task { await load() }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var accountSection: some View {
        if let profile {
            Section("Account") {
                LabeledContent("Email", value: profile.email)
                LabeledContent("Plan", value: profile.plan.capitalized)
                if profile.plan == "free" {
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Upgrade to Pro", systemImage: "sparkles")
                    }
                }
                Button("Log out", role: .destructive) {
                    Task {
                        await APIClient.shared.logout()
                        await APIClient.shared.warmUp() // back to anonymous device
                        self.profile = nil
                        await load()
                    }
                }
            }
        } else {
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                SecureField("Password (8+ characters)", text: $password)
                    .textContentType(isRegistering ? .newPassword : .password)

                Button {
                    submitAuth()
                } label: {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(isRegistering ? "Create account" : "Log in")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(email.isEmpty || password.count < 8 || isSubmitting)

                Button(
                    isRegistering
                        ? "Already have an account? Log in"
                        : "New here? Create an account"
                ) {
                    isRegistering.toggle()
                }
                .font(.footnote)
            } header: {
                Text("Account")
            } footer: {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                } else {
                    Text("Optional — your history syncs across devices with an account.")
                }
            }
        }
    }

    private var historySection: some View {
        Section {
            Toggle(
                "Save history",
                isOn: Binding(
                    get: { profile?.historyOptIn ?? false },
                    set: { newValue in updateHistoryOptIn(newValue) }
                )
            )
        } header: {
            Text("Privacy")
        } footer: {
            Text(
                "Off by default. When on, your messages and suggestions are stored so you can revisit them in History. Turn off anytime."
            )
        }
    }

    @ViewBuilder
    private var usageSection: some View {
        if let usage {
            Section("Usage today") {
                LabeledContent("Generations", value: "\(usage.used)")
                if let limit = usage.limit, usage.enforced {
                    LabeledContent("Daily limit", value: "\(limit)")
                } else {
                    LabeledContent("Daily limit", value: "Unlimited during beta ✨")
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "0.3.0")
            Link(
                "How to enable the keyboard",
                destination: URL(string: UIApplication.openSettingsURLString)!
            )
        }
    }

    // MARK: - Actions

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await APIClient.shared.me().user
            usage = try await APIClient.shared.usage()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func submitAuth() {
        isSubmitting = true
        errorMessage = nil
        Task {
            defer { isSubmitting = false }
            do {
                if isRegistering {
                    _ = try await APIClient.shared.register(email: email, password: password)
                } else {
                    _ = try await APIClient.shared.login(email: email, password: password)
                }
                password = ""
                await load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func updateHistoryOptIn(_ value: Bool) {
        Task {
            do {
                profile = try await APIClient.shared.updateProfile(
                    UpdateProfileRequest(historyOptIn: value)
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
