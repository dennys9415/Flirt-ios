import Foundation
import SwiftUI

@MainActor
final class ReplyGeneratorViewModel: ObservableObject {
    @Published var message = ""
    @Published var selectedTone: Tone = .lightFlirt
    @Published var suggestions: [Suggestion] = []
    @Published var isGenerating = false
    @Published var refiningId: String?
    @Published var errorMessage: String?
    @Published var copiedId: String?

    var canGenerate: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating
    }

    func generate() {
        guard canGenerate else { return }
        isGenerating = true
        errorMessage = nil
        suggestions = []
        Task {
            defer { isGenerating = false }
            do {
                let response = try await APIClient.shared.generateReplies(
                    message: message,
                    tone: selectedTone
                )
                suggestions = response.suggestions
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func refine(_ suggestion: Suggestion, action: RefineAction) {
        guard refiningId == nil else { return }
        refiningId = suggestion.id
        errorMessage = nil
        Task {
            defer { refiningId = nil }
            do {
                let refined = try await APIClient.shared.refine(
                    text: suggestion.text,
                    action: action
                )
                if let index = suggestions.firstIndex(of: suggestion) {
                    suggestions[index].text = refined.text
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func copy(_ suggestion: Suggestion) {
        UIPasteboard.general.string = suggestion.text
        copiedId = suggestion.id
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            if copiedId == suggestion.id { copiedId = nil }
        }
    }

    func updateText(for suggestion: Suggestion, to newText: String) {
        if let index = suggestions.firstIndex(of: suggestion) {
            suggestions[index].text = newText
        }
    }
}
