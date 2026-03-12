import SwiftUI
import SwiftData

/// App entry point. Shows Zener card info, recent history summary, and
/// a "Let's Play" button that leads to the round picker.
struct WelcomeView: View {
    @Query(sort: \GameSession.date, order: .reverse) private var sessions: [GameSession]

    // Fix #26: safe URL — if it ever fails to parse, the link is simply not shown
    private let wikiURL = URL(string: "https://en.wikipedia.org/wiki/Zener_cards#:~:text=Zener%20cards%20are%20cards%20used,colleague%2C%20parapsychologist%20J.%20B.%20Rhine%20(1895%E2%80%931980).")

    private var totalGames: Int { sessions.count }

    private var allTimeAccuracy: Double {
        guard !sessions.isEmpty else { return 0 }
        let totalScore = sessions.reduce(0) { $0 + $1.score }
        let totalRounds = sessions.reduce(0) { $0 + $1.roundCount }
        guard totalRounds > 0 else { return 0 }
        return Double(totalScore) / Double(totalRounds) * 100
    }

    private var bestSession: GameSession? {
        sessions.max { $0.accuracyPercent < $1.accuracyPercent }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // MARK: Header
                VStack(spacing: 10) {
                    // Fix #15: decorative icon, hidden from accessibility
                    Text("★")
                        .font(.system(size: 72))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)

                    Text("Zener Wave")
                        .font(.largeTitle).bold()

                    Text("An ESP experiment")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 48)

                // MARK: What are Zener cards?
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are Zener cards?")
                        .font(.headline)

                    Text("Zener cards were developed in the 1930s by perceptual psychologist Karl Zener to test for extrasensory perception (ESP). Each deck contains 25 cards — 5 each of five simple symbols: circle, cross, wavy lines, square, and star.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("In a classic test, a sender concentrates on a hidden card while the receiver tries to guess the symbol using only intuition. Pure chance gives a 20% hit rate (5 correct out of 25). Scoring significantly above chance is taken as evidence of ESP.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Fix #26: optional URL, link only shown if URL parses
                    if let wikiURL {
                        Link(destination: wikiURL) {
                            Label("Learn more on Wikipedia", systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 24)

                // MARK: How to play
                VStack(alignment: .leading, spacing: 10) {
                    Text("How to play")
                        .font(.headline)

                    Text("A card is drawn at random and hidden from you. Focus your mind, then tap the symbol you feel is correct. Your score and a statistical interpretation are shown at the end — the app will tell you how likely your result was by chance alone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                // MARK: History summary (only shown if games have been played)
                if !sessions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Stats")
                            .font(.headline)

                        HStack(spacing: 0) {
                            statTile(value: "\(totalGames)", label: "Games")
                            Divider().frame(height: 40)
                            statTile(
                                value: String(format: "%.0f%%", allTimeAccuracy),
                                label: "Accuracy"
                            )
                            if let best = bestSession {
                                Divider().frame(height: 40)
                                statTile(
                                    value: "\(best.score)/\(best.roundCount)",
                                    label: "Best Score"
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }

                // MARK: Let's Play
                NavigationLink {
                    RoundPickerView()
                } label: {
                    Text("Let's Play")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
    }

    @ViewBuilder
    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3).bold()
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
    .modelContainer(for: GameSession.self, inMemory: true)
}
