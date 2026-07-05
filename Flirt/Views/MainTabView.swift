import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ReplyGeneratorView()
                .tabItem { Label("Generate", systemImage: "sparkles") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
