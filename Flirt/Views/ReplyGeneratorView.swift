import SwiftUI

struct ReplyGeneratorView: View {
    @StateObject private var viewModel = ReplyGeneratorViewModel()
    @FocusState private var messageFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    messageInput
                    toneSelector
                    generateButton
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                    suggestionsList
                }
                .padding()
            }
            .navigationTitle("Flirt")
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // MARK: - Sections

    private var messageInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Received message")
                .font(.headline)
            TextEditor(text: $viewModel.message)
                .focused($messageFocused)
                .frame(minHeight: 90)
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if viewModel.message.isEmpty {
                        Text("Paste the message you received…")
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                            .padding(.leading, 13)
                            .allowsHitTesting(false)
                    }
                }
            HStack {
                Button {
                    if let clipboard = UIPasteboard.general.string {
                        viewModel.message = clipboard
                    }
                } label: {
                    Label("Paste", systemImage: "doc.on.clipboard")
                }
                .buttonStyle(.bordered)

                if !viewModel.message.isEmpty {
                    Button(role: .destructive) {
                        viewModel.message = ""
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .font(.subheadline)
        }
    }

    private var toneSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tone")
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Tone.allCases) { tone in
                        Button {
                            viewModel.selectedTone = tone
                        } label: {
                            Text(tone.label)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    viewModel.selectedTone == tone
                                        ? Color.accentColor
                                        : Color(.secondarySystemBackground)
                                )
                                .foregroundStyle(
                                    viewModel.selectedTone == tone ? .white : .primary
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var generateButton: some View {
        Button {
            messageFocused = false
            viewModel.generate()
        } label: {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isGenerating ? "Generating…" : "Generate replies")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.canGenerate)
    }

    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.suggestions.isEmpty {
                Text("Suggestions")
                    .font(.headline)
            }
            ForEach(viewModel.suggestions) { suggestion in
                SuggestionCard(
                    suggestion: suggestion,
                    isRefining: viewModel.refiningId == suggestion.id,
                    isCopied: viewModel.copiedId == suggestion.id,
                    onCopy: { viewModel.copy(suggestion) },
                    onRefine: { action in viewModel.refine(suggestion, action: action) },
                    onEdit: { newText in viewModel.updateText(for: suggestion, to: newText) }
                )
            }
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(.white)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ReplyGeneratorView()
}
