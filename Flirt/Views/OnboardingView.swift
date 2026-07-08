import SwiftUI

/// First-launch onboarding. The critical job: get the keyboard enabled —
/// it's the whole product. Kept to 3 screens, skippable.
struct OnboardingView: View {
    let onDone: () -> Void
    @State private var page = 0

    var body: some View {
        VStack {
            TabView(selection: $page) {
                welcome.tag(0)
                keyboardSetup.tag(1)
                howToUse.tag(2)
                account.tag(3)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            if page < 3 {
                Button {
                    withAnimation { page += 1 }
                } label: {
                    Text("Next")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }

            Button(page < 3 ? "Skip" : "Skip — I'll do it later in Settings") { onDone() }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(.bottom, 24)
    }

    private var account: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("Your account (optional)")
                    .font(.title2.bold())
                Text("Sync your history and settings across devices. You can always skip and use Flirt anonymously.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                AuthFormView {
                    onDone()
                }
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var welcome: some View {
        pageContent(
            icon: "sparkles",
            title: "Welcome to Flirt",
            lines: [
                "Never stare at a message wondering what to reply.",
                "Pick a tone — get three replies that sound like you.",
            ]
        )
    }

    private var keyboardSetup: some View {
        pageContent(
            icon: "keyboard",
            title: "Enable the Flirt Keyboard",
            lines: [
                "Settings → General → Keyboard → Keyboards",
                "Add New Keyboard → Flirt",
                "Then tap Flirt again → Allow Full Access",
                "Full Access lets the keyboard reach our AI. We only send the message you're replying to — never your keystrokes.",
            ]
        )
    }

    private var howToUse: some View {
        pageContent(
            icon: "hand.tap",
            title: "Use it anywhere",
            lines: [
                "1. Copy the message you received",
                "2. Switch to the Flirt keyboard (globe 🌐)",
                "3. Pick a tone and tap a suggestion — it types itself ✨",
            ]
        )
    }

    private func pageContent(icon: String, title: String, lines: [String]) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 28)
            Spacer()
        }
    }
}
