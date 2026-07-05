import SwiftUI

struct KeyboardView: View {
    let hasFullAccess: Bool
    let needsGlobe: Bool
    let actions: KeyboardActions

    @StateObject private var model = KeyboardViewModel()

    var body: some View {
        VStack(spacing: 8) {
            if !hasFullAccess {
                infoState(
                    icon: "lock.shield",
                    title: "Enable Full Access",
                    detail: "Settings → General → Keyboard → Keyboards → Flirt → Allow Full Access. Flirt only sends the message you reply to — never your keystrokes."
                )
            } else {
                switch model.state {
                case .idle:
                    toneRow
                    generateButton
                case .loading:
                    ProgressView("Generating…")
                        .frame(maxHeight: .infinity)
                case .suggestions(let suggestions):
                    suggestionList(suggestions)
                case .error(let message):
                    infoState(icon: "exclamationmark.triangle", title: "Oops", detail: message)
                    Button("Try again") { model.reset() }
                        .buttonStyle(.borderedProminent)
                }
            }
            bottomBar
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Sections

    private var toneRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Tone.allCases) { tone in
                    Button {
                        model.selectedTone = tone
                    } label: {
                        Text(tone.label)
                            .font(.footnote.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                model.selectedTone == tone
                                    ? Color.accentColor
                                    : Color(.secondarySystemGroupedBackground)
                            )
                            .foregroundStyle(model.selectedTone == tone ? .white : .primary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var generateButton: some View {
        VStack(spacing: 6) {
            Button {
                model.generate(contextText: actions.contextText())
            } label: {
                Label("Reply to copied message", systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Text("Copy the message you received, then tap")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }

    private func suggestionList(_ suggestions: [Suggestion]) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(suggestions) { suggestion in
                    Button {
                        actions.insertText(suggestion.text)
                    } label: {
                        Text(suggestion.text)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            if needsGlobe {
                Button {
                    actions.switchKeyboard()
                } label: {
                    Image(systemName: "globe")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            if case .suggestions = model.state {
                Button {
                    model.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .padding(8)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private func infoState(icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(title).font(.subheadline.weight(.semibold))
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View model

@MainActor
final class KeyboardViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case suggestions([Suggestion])
        case error(String)
    }

    @Published var state: State = .idle
    @Published var selectedTone: Tone = AppGroupStore.selectedTone {
        didSet { AppGroupStore.selectedTone = selectedTone }
    }

    func generate(contextText: String?) {
        // The received message: clipboard first (the natural flow — the user
        // copies the message in the chat), then any text already in the field.
        let clipboard = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let context = contextText?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let message = [clipboard, context].compactMap({ $0 }).first(where: { !$0.isEmpty }) else {
            state = .error("Copy the message you want to reply to, then try again")
            return
        }

        state = .loading
        Task {
            do {
                let response = try await APIClient.shared.generateReplies(
                    message: message,
                    tone: selectedTone
                )
                state = .suggestions(response.suggestions)
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func reset() {
        state = .idle
    }
}
