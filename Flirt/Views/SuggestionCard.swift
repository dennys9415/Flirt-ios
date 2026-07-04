import SwiftUI

struct SuggestionCard: View {
    let suggestion: Suggestion
    let isRefining: Bool
    let isCopied: Bool
    let onCopy: () -> Void
    let onRefine: (RefineAction) -> Void
    let onEdit: (String) -> Void

    @State private var isEditing = false
    @State private var draft = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isEditing {
                TextEditor(text: $draft)
                    .frame(minHeight: 70)
                    .padding(4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                HStack {
                    Button("Save") {
                        onEdit(draft)
                        isEditing = false
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Cancel") { isEditing = false }
                        .buttonStyle(.bordered)
                }
                .font(.subheadline)
            } else {
                Text(suggestion.text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    Button {
                        onCopy()
                    } label: {
                        Label(
                            isCopied ? "Copied!" : "Copy",
                            systemImage: isCopied ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isCopied ? .green : .accentColor)

                    Button {
                        draft = suggestion.text
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if isRefining {
                        ProgressView()
                    } else {
                        Menu {
                            ForEach(RefineAction.allCases) { action in
                                Button(action.label) { onRefine(action) }
                            }
                        } label: {
                            Image(systemName: "wand.and.stars")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .font(.subheadline)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
