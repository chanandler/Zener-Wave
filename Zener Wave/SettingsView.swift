import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("preferredRoundCount") private var preferredRoundCount: Int = 25
    @AppStorage("soundsEnabled") private var soundsEnabled: Bool = true

    var body: some View {
        List {
            // MARK: - Game
            Section("Game") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rounds per game")
                        .font(.subheadline)
                    Picker("Rounds", selection: $preferredRoundCount) {
                        Text("5").tag(5)
                        Text("10").tag(10)
                        Text("25").tag(25)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)

                Toggle("Sound Effects", isOn: $soundsEnabled)
            }

            // MARK: - App Links
            Section("App") {
                NavigationLink {
                    HistoryView()
                } label: {
                    Label("History", systemImage: "chart.bar")
                }

                NavigationLink {
                    AboutView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }

                TipJarNavigationRow()
            }

            // MARK: - Support
            Section("Support") {
                if let reviewURL = URL(string: "https://apps.apple.com/app/id6741981961?action=write-review") {
                    Link(destination: reviewURL) {
                        Label("Rate Zener Wave", systemImage: "star")
                    }
                }

                if let privacyURL = URL(string: "https://clintyarwood.com/zenerwave/privacy") {
                    Link(destination: privacyURL) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A row that opens TipJarView as a sheet, used inside the Settings list
private struct TipJarNavigationRow: View {
    @State private var showingTipJar = false

    var body: some View {
        Button {
            showingTipJar = true
        } label: {
            Label("Tip Jar", systemImage: "heart.fill")
                .foregroundStyle(.primary)
        }
        .sheet(isPresented: $showingTipJar) {
            TipJarView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
