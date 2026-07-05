import SwiftUI

struct HistoryView: View {
    @State private var entries: [HistoryEntry] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && entries.isEmpty {
                    ProgressView()
                } else if entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("History")
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private var list: some View {
        List(entries) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.message)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                ForEach(entry.suggestions) { suggestion in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 3)
                        Text(suggestion.text)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .contextMenu {
                        Button("Copy") {
                            UIPasteboard.general.string = suggestion.text
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No history yet")
                .font(.headline)
            Text(
                errorMessage
                    ?? "Turn on \"Save history\" in Settings and your generations will appear here. Only saved with your permission."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await APIClient.shared.history().entries
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
