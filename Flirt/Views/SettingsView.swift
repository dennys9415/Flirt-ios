import SwiftUI

struct SettingsView: View {
    @State private var profile: UserProfile?
    @State private var usage: UsageSummary?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var showPaywall = false

    // BYOK
    @State private var aiSettings: AiSettingsView_DTO?
    @State private var newProvider: AiProviderChoice = .gemini
    @State private var newApiKey = ""
    @State private var newModel = ""
    @State private var isSavingKey = false

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                if profile != nil {
                    aiProviderSection
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
                if let username = profile.username {
                    LabeledContent("Username", value: "@\(username)")
                }
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
                AuthFormView {
                    Task { await load() }
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Optional — your history syncs across devices with an account.")
            }
        }
    }

    // MARK: - BYOK

    private var aiProviderSection: some View {
        Section {
            if let current = aiSettings {
                LabeledContent("Provider", value: AiProviderChoice(rawValue: current.provider)?.label ?? current.provider)
                LabeledContent("API key", value: current.apiKeyMasked)
                if let model = current.model {
                    LabeledContent("Model", value: model)
                }
                Button("Remove my key", role: .destructive) {
                    Task {
                        try? await APIClient.shared.deleteAiSettings()
                        aiSettings = nil
                    }
                }
            } else {
                Picker("Provider", selection: $newProvider) {
                    ForEach(AiProviderChoice.allCases) { choice in
                        Text(choice.label).tag(choice)
                    }
                }
                SecureField("API key", text: $newApiKey)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                TextField("Model (optional)", text: $newModel)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                Button("Save key") {
                    saveAiKey()
                }
                .disabled(newApiKey.count < 8 || isSavingKey)
            }
        } header: {
            Text("AI Provider (your own key)")
        } footer: {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            } else if aiSettings != nil {
                Text("Your replies are generated with your key, on your provider's bill.")
            } else {
                Text("Optional — use your own OpenAI / Claude / Gemini key. Stored encrypted; only a masked version is ever shown.")
            }
        }
    }

    private func saveAiKey() {
        isSavingKey = true
        errorMessage = nil
        Task {
            defer { isSavingKey = false }
            do {
                aiSettings = try await APIClient.shared.setAiSettings(
                    provider: newProvider,
                    apiKey: newApiKey,
                    model: newModel
                )
                newApiKey = ""
                newModel = ""
            } catch {
                errorMessage = error.localizedDescription
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
            if profile != nil {
                aiSettings = try await APIClient.shared.aiSettings().settings
            } else {
                aiSettings = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
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
